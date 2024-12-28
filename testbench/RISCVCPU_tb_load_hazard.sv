`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`timescale 1ns/1ps

module RISCVCPU_tb_load_hazard;

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

        // -- Program: place instructions in IMem --
        // instructions to test load hazard
        dut.imem.IMem[0] = 32'h00002083; // lw x1, 0(x0)
        dut.imem.IMem[1] = 32'h00108133; // add  x2, x1, x1
        dut.imem.IMem[2] = 32'h00000013; // NOP
        dut.imem.IMem[3] = 32'h00202223; // sw   x2, 4(x0)
        dut.imem.IMem[4] = 32'h00402183; // lw   x3, 4(x0)
        dut.imem.IMem[5] = 32'h00118233; // add  x4, x3, x1
        dut.imem.IMem[6] = 32'h00402423; // sw   x4, 8(x0) 
        dut.imem.IMem[7] = 32'h00c00293; // addi x5, x0, 12
        dut.imem.IMem[8] = 32'h0052a023; // sw x5, 0(x5)
        dut.imem.IMem[9] = 32'h0002a303; // lw x6, 0(x5)
        dut.imem.IMem[10] = 32'h00632223; // sw x6, 4(x6)
        dut.imem.IMem[11] = 32'h00000013;

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
        repeat (500) @(posedge clock); 
        

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
        // x1=5, x2=10, x3=10, x4=15, x5=15
        // Also check DMEM[0] == 5, DMEM[1] == 10, DMEM[2] == 15

        check_reg(1,   5);
        check_reg(2,   10);
        check_reg(3,   10);
        check_reg(4,   15);
        check_reg(5,    12);
        check_reg(6,   12);

        check_dmem(0, 5);
        check_dmem(1, 10);
        check_dmem(2, 15);
        check_dmem(3, 12);
        check_dmem(4, 12);

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
