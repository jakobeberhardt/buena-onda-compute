module IMemory(
    input  logic [31:0] addr,
    output logic [31:0] dataOut
);
    logic [31:0] IMem[0:1023];
    assign dataOut = IMem[addr];
endmodule
