`define DEBUG 1  // Set to 1 to enable debug prints, 0 to disable
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

    // print when data is written
    always @(posedge clock) begin
        if (`DEBUG) begin
            if (op == SW) begin
                $display("Time: %0t, DMEM[%0d] <= %h",$time, addr, writeData);
                $display("Time: %0t, Current DMEM[%0d] = %h",$time, addr, DMem[addr]);
            end
        end
    end



endmodule
