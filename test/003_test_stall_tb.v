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
