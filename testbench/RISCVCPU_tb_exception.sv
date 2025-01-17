`define DEBUG 1  // Set to 1 to enable debug prints, 0 to disable
`timescale 1ns/1ps

module RISCVCPU_tb_exception;

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

    initial begin
        // VCD output filename
        $dumpfile("RISCVCPU_tb_exception.vcd");
        // Dump everything in this testbench hierarchy
        $dumpvars(0, RISCVCPU_tb_exception);
    end

    // Clock Generation: 10ns Period (100MHz)
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // Toggle clock every 5ns
    end

    typedef bit [31:0] word_type;
    typedef bit [127:0] cache_data_type;

    // Temporary array to hold 32-bit words
    word_type temp_DMem_words [0:4095]; // Adjust size as needed

    
    // ----------------------------------
    // IMem and DMem Initialization
    // ----------------------------------
    initial begin
        // Clear entire IMem to 0 just in case
        for (int i = 0; i < 256; i++) begin
            dut.imem.IMem[i] = 32'h00000013; // default = NOP
        end

        // -- Program: place instructions in IMem --
        dut.imem.IMem[0] = 32'h00500093; // addi x1, x0, 5
        dut.imem.IMem[1] = 32'h00300113; // addi x2, x0, 3
        dut.imem.IMem[2] = 32'h001020a3; // sw   x5, 1(x0) // cause exception
        dut.imem.IMem[3] = 32'h40208233; // sub  x4, x1, x2
        dut.imem.IMem[4] = 32'h022082B3; // mul  x5, x1, x2
        dut.imem.IMem[5] = 32'h06400313; // addi x6, x0, 100
        dut.imem.IMem[6] = 32'h005303b3; // add  x7, x6, x5
        dut.imem.IMem[7] = 32'h002081B3; // add  x3, x1, x2
        dut.imem.IMem[8] = 32'h00000013; // nop
        dut.imem.IMem[9] = 32'h00000013; // nop
        //force cache data into main memory by writing exact lines of cache memory
        dut.imem.IMem[10] = 32'h0000007f; // SPecial Instruction to Drain cache to DMEM


        // Load DMem
        // Load 32-bit words from the data file
        $readmemh("testbench/data/dmem.dat", temp_DMem_words);

        // Pack every four 32-bit words into one 128-bit block
        for (int i = 0; i < 1024; i++) begin
            dut.mem_stage.main_memory.memArray[i] = {temp_DMem_words[4*i + 3],
                                temp_DMem_words[4*i + 2],
                                temp_DMem_words[4*i + 1],
                                temp_DMem_words[4*i]};
        end

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
        repeat (50) @(posedge clock); 
        

        // Display Register Values After Execution
        $display("==== Final Register File ====");
        for (int i = 0; i <= 12; i = i + 1) begin
            $display("After execution, x%d = %d", i, dut.regfile.Regs[i]);
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
        // x1=5, x2=3, x3=8, x4=2, x5=15, x6=100, x7=115
        // Also check DMEM[0] == 15

        check_reg(1,   5);
        check_reg(2,   2);
        check_reg(3,   3);
        check_reg(4,   4);
        check_reg(5,  5);
        check_reg(6, 6);
        check_reg(7, 7);

        // Accessing word0 (bits [31:0]) of memArray[0]
        if (dut.mem_stage.main_memory.memArray[0][31:0] == 32'd5) begin
            $display("DMEM[0][31:0] PASS: got %0d, expected 5", dut.mem_stage.main_memory.memArray[0][31:0]);
            pass_count++;
        end else begin
            $display("DMEM[0][31:0] FAIL: got %0d, expected 5", dut.mem_stage.main_memory.memArray[0][31:0]);
            fail_count++;
        end

        if (fail_count == 0)
            $display("[TEST PASS] All checks passed!");
        else
            $display("[TEST FAIL] %0d passes, %0d fails.", pass_count, fail_count);
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
            $display("***************************************************BEGIN OF CYCLE***************************************************");
            $display("Cycle: %0d", cycle_count - 2);
            $display("Time: %0t | PC = %d, IR(IF stage) = %h", $time, dut.if_stage.PC, dut.if_id_bus_in.instruction);
            $display("Time: %0t | PC = %d, IR(ID stage) = %p", $time, dut.if_stage.PC, dut.id_ex_bus_in);
            $display("Time: %0t | PC = %d, IR(EX stage) = %p", $time, dut.if_stage.PC, dut.ex_mem_bus_in);
            $display("Time: %0t | PC = %d IR(MEM stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_in);
            $display("Time: %0t | PC = %d, IR(MEM OUT stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_out);
            $display("Time: %0t | PC = %d, Control Signal = %p", $time, dut.if_stage.PC, dut.ctrl_signals);
        end
    end

endmodule
