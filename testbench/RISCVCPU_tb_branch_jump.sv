`define DEBUG 1  // Set to 1 to enable debug prints, 0 to disable
`timescale 1ns/1ps

module RISCVCPU_tb_branch_jump;

    // Clock and Reset Signals
    logic clock;
    logic reset;

    // Cycle Counter (Using 64-bit to prevent overflow)
    reg [63:0] cycle_count;

    // Instantiate the DUT (Design Under Test)
    RISCVCPU dut (
        .clock(clock),
        .reset(reset)
    );

    // Clock Generation: 10ns Period (100MHz)
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // Toggle clock every 5ns
    end

    
    // ----------------------------------
    // IMem and DMem Initialization
    // ----------------------------------
    initial begin
        // Clear entire IMem to 0 just in case
        for (int i = 0; i < 256; i++) begin
            dut.imem.IMem[i] = 32'h00000013; // default = NOP
        end

        // Load DMem
        $readmemh("testbench/data/dmem.dat", dut.dmem.DMem);

        //dut.regfile.Regs[7] = 64; 

        // -- Program: place instructions in IMem --
        // instructions to test load hazard
        dut.imem.IMem[0] = 32'h00002083; // lw x1, 0(x0)
        dut.imem.IMem[1] = 32'h00a00113; // addi x2, x0, 10
        dut.imem.IMem[2] = 32'h00010263; // beq x2, x0, 4
        dut.imem.IMem[3] = 32'h002081b3; // add x3, x1, x2
        dut.imem.IMem[4] = 32'h00218263; // beq x3, x2, 4
        dut.imem.IMem[5] = 32'h40118233; // sub x4, x3, x1
        dut.imem.IMem[6] = 32'h00402223; // sw x4, 4(x0) 
        dut.imem.IMem[7] = 32'h00402283; // lw x5, 4(x0)
        dut.imem.IMem[8] = 32'h00228263; // beq x5, x2, 4
        dut.imem.IMem[9] = 32'h3e700313; // addi x6, x0, 9999
        dut.imem.IMem[10] = 32'h00128333; // add x6, x5, x1
        dut.imem.IMem[11] = 32'h04000393; // addi x7, x0, 64
        dut.imem.IMem[12] = 32'h00038467; // jalr x8, 0(x7)
        dut.imem.IMem[13] = 32'h00000013; // NOP
        dut.imem.IMem[14] = 32'h00000013; // NOP
        dut.imem.IMem[15] = 32'h00000013; // NOP
        // Code at address 16 => PC=16*4=64
        dut.imem.IMem[16] = 32'h4d200493; // addi x9, x0, 1234
        dut.imem.IMem[17] = 32'h00902423; // sw x9, 8(x0)


        dut.dmem.DMem[0] = 32'h00000005; // DMEM[0] = 5
        
        
        

    end

    // Initial Block for Reset and Simulation Control
    initial begin
        // Initialize Cycle Counter
        cycle_count = 0;

        // Apply Reset
        reset = 1;
        repeat (2) @(posedge clock); // Hold reset for 2 clock cycles
        reset = 0;

        // Run Simulation for Sufficient Cycles to Execute Instructions
        repeat (25) @(posedge clock); 
        

        // Display Register Values After Execution
        $display("==== Final Register File ====");
        for (int i = 0; i <= 12; i = i + 1) begin
            $display("After execution, x%d = %d", i, dut.regfile.Regs[i]);
        end

        //print top 5 values of DMEM
        for (int i = 0; i < 10; i = i + 1) begin
            $display("DMEM[%0d] = %0d", i, dut.dmem.DMem[i]);
        end


        // Verify Key Registers
        check_results();

        // End Simulation
        $finish;
    end


     task automatic check_results();
        int pass_count = 0;
        int fail_count = 0;

        // We'll check only the registers we care about:


        check_reg(1,  5); // load x1, 0(x0)
        check_reg(2, 10); // (stored by "addi x2, x0, 10")
        check_reg(3, 15); // (stored by "add x3, x1, x2"), (x1 + x2 = 5 + 10)
        check_reg(4, 10); // (stored by "sub x4, x3, x1"), (x3 - x1 = 15 - 5)
        check_reg(5, 10); // (stored by "lw x5, 4(x0)"), which is 10
        check_reg(6, 15); // (stored by "add x6, x5, x1"), (x5 + x1 = 10 + 5)
        check_reg(7, 64); // (stored by "addi x7, x0, 64")
        check_reg(9, 1234); //(addi x9, x0, 1234 at PC=64 after the jalr)

        check_dmem(0, 5); //(initial data, remains unchanged)
        check_dmem(1, 10); // (stored by "sw x4, 4(x0)")
        check_dmem(2, 1234); //1234 (stored at the jump target "sw x9, 8(x0)")
        

        if (fail_count == 0)
            $display("[TEST PASS] All checks passed!");
        else
            $display("[TEST FAIL] %0d passes, %0d fails.", pass_count, fail_count);
    endtask

    task check_dmem(input int addr, input int expected);
        if (dut.dmem.DMem[addr] == expected) begin
            $display("DMEM[%0d] PASS: got %0d, expected %0d", 
                     addr, dut.dmem.DMem[addr], expected);
        end else begin
            $display("DMEM[%0d] FAIL: got %0d, expected %0d", 
                     addr, dut.dmem.DMem[addr], expected);
        end
    endtask

    // Helper task to check a single register
    task check_reg(input int regnum, input int expected);
        if (dut.regfile.Regs[regnum] == expected) begin
            $display("x%0d PASS: got %0d, expected %0d", 
                     regnum, dut.regfile.Regs[regnum], expected);
        end else begin
            $display("x%0d FAIL: got %0d, expected %0d", 
                     regnum, dut.regfile.Regs[regnum], expected);
        end
    endtask

    // Always Block to Monitor and Display Cycle Information
    always @(posedge clock) begin
        // Increment Cycle Counter
        cycle_count = cycle_count + 1;

        // Display Cycle Information 
        if (`DEBUG) begin
            $display("Cycle: %0d", cycle_count - 2);
            $display("Time: %0t | PC = %0d, IR(IF-ID stage) = %h", $time, dut.if_stage.PC, dut.if_id_bus_in.instruction);
            $display("Time: %0t | PC = %0d, IR(ID-EX stage) = %p", $time, dut.if_stage.PC, dut.id_ex_bus_in);
            $display("Time: %0t | PC = %0d, IR(EX-MEM stage) = %p", $time, dut.if_stage.PC, dut.ex_mem_bus_in);
            $display("Time: %0t | PC = %0d, IR(MEM-WB stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_in);
            $display("Time: %0t | PC = %0d, IR(MEM OUT stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_out);
            $display("Time: %0t | PC = %0d, Control Signal = %p", $time, dut.if_stage.PC, dut.ctrl_signals);
            $display("***************************************************END OF CYCLE***************************************************");
        end
    end

endmodule
