`timescale 1ns / 1ps

module counter_tb;

    // Inputs
    reg clk;
    reg rst;

    // Outputs
    wire [3:0] count;

    // Instantiate the Unit Under Test (UUT)
    counter uut (
        .clk(clk),
        .rst(rst),
        .count(count)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock toggles every 5 ns (100 MHz)
    end

    initial begin
        rst = 1;     
        #10;        
        rst = 0;  

        #80;

        rst = 1;
        #10;
        rst = 0;

        #50;

        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("counter_waveform.vcd");
        $dumpvars(0, counter_tb);
    end

endmodule
