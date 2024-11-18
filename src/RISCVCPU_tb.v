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

        // Load instructions into instruction memory
        $readmemh("imem.dat", uut.IMemory);

        // Load data into data memory
        $readmemh("dmem.dat", uut.DMemory);

        // Run the simulation for a certain amount of time
        #1000;

        // Optionally, print the final values of the data memory
        // For example, print the first 10 memory locations
        $display("Final Data Memory Values:");
        for (i = 0; i < 10; i = i + 1) begin
            $display("DMemory[%0d] = %0d (0x%0h)", i, uut.DMemory[i], uut.DMemory[i]);
        end

        // Optionally, print the final values of the registers
        $display("Final Register Values:");
        for (i = 0; i <= 31; i = i + 1) begin
            $display("x%0d = %0d (0x%0h)", i, uut.Regs[i], uut.Regs[i]);
        end

        $finish;
    end

    // Clock generator
    always #5 clock = ~clock; // Clock period is 10ns (100MHz)

endmodule
