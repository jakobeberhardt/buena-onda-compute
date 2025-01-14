module IMemory(
    input  logic [31:0] addr,        // Word-aligned address
    output logic [127:0] dataOut     // 128-bit output (4 words)
);
    logic [31:0] IMem [0:1023];


    assign dataOut = {
        IMem[addr],
        IMem[addr+1],
        IMem[addr+2],
        IMem[addr+3]
    };

endmodule
