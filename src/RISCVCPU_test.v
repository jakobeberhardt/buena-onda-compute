`timescale 1ns/1ps

module RISCVCPU_tb;

    // Clock signal
    reg clock;

    // Instantiate the RISCVCPU module
    RISCVCPU uut (
        .clock(clock)
    );

    integer i;

    initial begin
        // Initialize clock
        clock = 0;

        // Initialize waveform dumping
        $dumpfile("RISCVCPU_tb.vcd");
        $dumpvars(0, RISCVCPU_tb);

        // ---------------------------------------------
        // Test Case 1: Basic Functionality Test
        // Load immediate 5 into x1 and x2, add them into x3
        // Verify that x0 remains zero
        // ---------------------------------------------

        // Clear instruction memory and registers
        for (i = 0; i < 10; i = i + 1) begin
            uut.IMemory[i] = uut.NOP;
        end
        for (i = 0; i <= 31; i = i + 1) begin
            uut.Regs[i] = 0;
        end

        // // Load instructions into instruction memory
        // // Instruction encodings:
        // // ADDI x1, x0, 5   --> 0x00500093
        // // ADDI x2, x0, 5   --> 0x00500113
        // // ADD  x3, x1, x2  --> 0x002081B3

        // uut.IMemory[0] = 32'h00500093; // ADDI x1, x0, 5
        // uut.IMemory[1] = 32'h00500113; // ADDI x2, x0, 5
        // uut.IMemory[2] = 32'h002081B3; // ADD x3, x1, x2

        // // Run the simulation for enough cycles
        // #100;

        // // Check the results
        // $display("\nTest Case 1: Basic Functionality Test");
        // if (uut.Regs[0] !== 0) begin
        //     $display("FAIL: x0 expected 0, got %0d", uut.Regs[0]);
        // end else if (uut.Regs[1] !== 5) begin
        //     $display("FAIL: x1 expected 5, got %0d", uut.Regs[1]);
        // end else if (uut.Regs[2] !== 5) begin
        //     $display("FAIL: x2 expected 5, got %0d", uut.Regs[2]);
        // end else if (uut.Regs[3] !== 10) begin
        //     $display("FAIL: x3 expected 10, got %0d", uut.Regs[3]);
        // end else begin
        //     $display("PASS: x0=%0d, x1=%0d, x2=%0d, x3=%0d", uut.Regs[0], uut.Regs[1], uut.Regs[2], uut.Regs[3]);
        // end

        // ---------------------------------------------
        // Test Case 2: Bypass Scenarios Test
        // Verify all bypassing cases
        // ---------------------------------------------

        // Clear instruction memory and registers
        for (i = 0; i < 10; i = i + 1) begin
            uut.IMemory[i] = uut.NOP;
        end
        for (i = 0; i <= 31; i = i + 1) begin
            uut.Regs[i] = 0;
        end

        // Load instructions to test bypassing
        // Instruction encodings:
        // ADDI x1, x0, 5       --> 0x00500093
        // ADDI x2, x0, 10      --> 0x00A00113
        // ADD  x3, x1, x2      --> 0x002081B3 (EX/MEM bypass to EX)
        // SUB  x4, x3, x1      --> 0x40118233 (MEM/WB bypass to EX)
        // AND  x5, x4, x2      --> 0x004222B3 (Bypass from different stages)
        // OR   x6, x5, x1      --> 0x0052A333 (No bypass needed)
        uut.IMemory[0] = 32'h00500093; // ADDI x1, x0, 5
        uut.IMemory[1] = 32'h00A00113; // ADDI x2, x0, 10
        uut.IMemory[2] = 32'h002081B3; // ADD x3, x1, x2
        uut.IMemory[3] = 32'h40318233; // SUB x4, x3, x1
        uut.IMemory[4] = 32'h004222B3; // AND x5, x4, x2
        uut.IMemory[5] = 32'h0052A333; // OR x6, x5, x1

        // Run the simulation
        #100;

        // Check the results
        $display("\nTest Case 2: Bypass Scenarios Test");
        if (uut.Regs[1] !== 5) begin
            $display("FAIL: x1 expected 5, got %0d", uut.Regs[1]);
        end else if (uut.Regs[2] !== 10) begin
            $display("FAIL: x2 expected 10, got %0d", uut.Regs[2]);
        end else if (uut.Regs[3] !== 15) begin
            $display("FAIL: x3 expected 15, got %0d", uut.Regs[3]);
        end else if (uut.Regs[4] !== 10) begin
            $display("FAIL: x4 expected 10, got %0d", uut.Regs[4]);
        end else if (uut.Regs[5] !== 10) begin
            $display("FAIL: x5 expected 10, got %0d", uut.Regs[5]);
        end else if (uut.Regs[6] !== 15) begin
            $display("FAIL: x6 expected 15, got %0d", uut.Regs[6]);
        end else begin
            $display("PASS: x1=%0d, x2=%0d, x3=%0d, x4=%0d, x5=%0d, x6=%0d", uut.Regs[1], uut.Regs[2], uut.Regs[3], uut.Regs[4], uut.Regs[5], uut.Regs[6]);
        end

        // ---------------------------------------------
        // Test Case 3: Stall Scenario Test
        // Verify that pipeline stalls when necessary
        // ---------------------------------------------

        // Clear instruction memory and registers
        for (i = 0; i < 10; i = i + 1) begin
            uut.IMemory[i] = uut.NOP;
        end
        for (i = 0; i <= 31; i = i + 1) begin
            uut.Regs[i] = 0;
        end

        // Load data into data memory
        uut.DMemory[0] = 42; // Data at address 0

        // Load instructions to test stalling
        // Instruction encodings:
        // LW   x1, 0(x0)      --> 0x00000103
        // ADDI x2, x1, 5      --> 0x00508113 (Depends on x1, should stall)
        // SW   x2, 4(x0)      --> 0x00200223

        uut.IMemory[0] = 32'h00000103; // LW x1, 0(x0)
        uut.IMemory[1] = 32'h00508113; // ADDI x2, x1, 5
        uut.IMemory[2] = 32'h00200223; // SW x2, 4(x0)

        // Run the simulation
        #200;

        // Check the results
        $display("\nTest Case 3: Stall Scenario Test");
        if (uut.Regs[1] !== 42) begin
            $display("FAIL: x1 expected 42, got %0d", uut.Regs[1]);
        end else if (uut.Regs[2] !== 47) begin
            $display("FAIL: x2 expected 47, got %0d", uut.Regs[2]);
        end else if (uut.DMemory[1] !== 47) begin
            $display("FAIL: DMemory[1] expected 47, got %0d", uut.DMemory[1]);
        end else begin
            $display("PASS: x1=%0d, x2=%0d, DMemory[1]=%0d", uut.Regs[1], uut.Regs[2], uut.DMemory[1]);
        end

        $finish;
    end

    // Clock generator
    always #5 clock = ~clock; // Clock period is 10ns (100MHz)

endmodule
