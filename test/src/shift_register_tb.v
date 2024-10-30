`timescale 1ns / 1ps

module shift_register_tb;

    reg i_clock = 0;

    shift_register uut (
        .i_clock(i_clock)
    );

    always #5 i_clock = ~i_clock;

    initial begin
        #100 $finish;
    end

    initial begin
        $dumpfile("shift_register_waveform.vcd");
        $dumpvars(0, shift_register_tb);
    end

endmodule
