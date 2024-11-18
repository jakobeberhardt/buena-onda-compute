`timescale 1ps/1ps


module fetch_decode;

    // Inputs
    reg i_clock;
    reg reset;

    // Outputs
    wire [3:0] pc;

    // Instantiate the Unit Under Test (UUT)
    fetch_decode uut (
        .i_clock(i_clock),
        .reset(reset),
        .pc(pc)
    );

    // Clock generation
    initial begin
        i_clock = 0;
        forever #5 i_clock = ~i_clock; // Clock toggles every 5 ns (100 MHz)
    end


	