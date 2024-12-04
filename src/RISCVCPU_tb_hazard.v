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

        // Clear instruction memory and registers
        for (i = 0; i < 10; i = i + 1) begin
            uut.IMemory[i] = uut.NOP;
        end
        for (i = 0; i <= 31; i = i + 1) begin
            uut.Regs[i] = 0;
        end
        // Initialize waveform dumping
        $dumpfile("RISCVCPU_tb.vcd");
        $dumpvars(0, RISCVCPU_tb);

        // Load instructions into instruction memory
        $readmemh("imemhazard.dat", uut.IMemory);

        // Run the simulation for a certain amount of time
        #200; // Adjust time as needed for simulation to complete

        // Assert and check the register values
        $display("Final Register Values:");
        for (i = 0; i <= 10; i = i + 1) begin
            $display("x%0d = %0d (0x%0h)", i, uut.Regs[i], uut.Regs[i]);
        end

        // Check if x3 is 0 and x4 is 10 as expected
        if (uut.Regs[3] !== 0) begin
            $display("Assertion failed: x3 should be 0 but is %0d", uut.Regs[3]);
            $stop;
        end else begin
            $display("Assertion passed: x3 is 0");
        end

        if (uut.Regs[4] !== 10) begin
            $display("Assertion failed: x4 should be 10 but is %0d", uut.Regs[4]);
            $stop;
        end else begin
            $display("Assertion passed: x4 is 10");
        end

        $display("All assertions passed.");

		$display("Final Data Memory Values:");
        for (i = 0; i < 5; i = i + 1) begin
            $display("DMemory[%0d] = %0d (0x%0h)", i, uut.DMemory[i], uut.DMemory[i]);
        end

        // Optionally, print the final values of the registers
        $display("Final Register Values:");
        for (i = 0; i <= 10; i = i + 1) begin
            $display("x%0d = %0d (0x%0h)", i, uut.Regs[i], uut.Regs[i]);
        end

        $finish;
    end

    // Clock generator
    always #5 clock = ~clock; // Clock period is 10ns (100MHz)

endmodule
