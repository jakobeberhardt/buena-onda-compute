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

        // Load instructions into instruction memory
        // Instruction encodings:
        // ADDI x1, x0, 5   --> 0x00500093
        // ADDI x2, x0, 5   --> 0x00500113
        // ADD  x3, x1, x2  --> 0x002081B3

        uut.IMemory[0] = 32'h00500093; // ADDI x1, x0, 5
        uut.IMemory[1] = 32'h00500113; // ADDI x2, x0, 5
        uut.IMemory[2] = 32'h002081B3; // ADD x3, x1, x2

        // Run the simulation for enough cycles
        #100;

        // Check the results
        $display("\nTest Case 1: Basic Functionality Test");
        if (uut.Regs[0] !== 0) begin
            $display("FAIL: x0 expected 0, got %0d", uut.Regs[0]);
        end else if (uut.Regs[1] !== 5) begin
            $display("FAIL: x1 expected 5, got %0d", uut.Regs[1]);
        end else if (uut.Regs[2] !== 5) begin
            $display("FAIL: x2 expected 5, got %0d", uut.Regs[2]);
        end else if (uut.Regs[3] !== 10) begin
            $display("FAIL: x3 expected 10, got %0d", uut.Regs[3]);
        end else begin
            $display("PASS: x0=%0d, x1=%0d, x2=%0d, x3=%0d", uut.Regs[0], uut.Regs[1], uut.Regs[2], uut.Regs[3]);
        end

        $finish;
    end 
    always #5 clock = ~clock; // Clock period is 10ns (100MHz)

endmodule
