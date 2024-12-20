`include "../core/utils/Opcodes.sv"

module DMemory(
    input logic clock,
    input [6:0] op,
    input [31:0] addr,
    input [31:0] writeData,
    output logic [31:0] readData
);


    logic [31:0] DMem[0:1023];
    assign readData = DMem[addr];

    always_ff @(posedge clock) begin
        if (op == SW) DMem[addr] <= writeData;
    end

endmodule
