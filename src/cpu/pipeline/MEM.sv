`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module MEM(
    input  logic clock,
    input  logic reset,
    input  wire ex_mem_bus_t ex_mem_bus_in,
    input  logic [31:0] dmemData,
    output mem_wb_bus_t mem_wb_bus_out
);

    logic [31:0] MEMWBValue;
    // Suppose we have a signal dmemData from top-level connected somehow:
    // For now, assume dmemData is available or just use a temporary placeholder.


    always_comb begin
        MEMWBValue = 0;
        if (ex_mem_bus_in.opcode == ALUopR || ex_mem_bus_in.opcode == ALUopI) begin
            MEMWBValue = ex_mem_bus_in.alu_result;
        end else if (ex_mem_bus_in.opcode == LW) begin
            // Replace with actual DMemory read data signal when integrated
            MEMWBValue = dmemData; 
        end else if (ex_mem_bus_in.opcode == SW) begin
            // Write happens at top-level. No assignment needed here.
            // Just leave it as is, no trailing semicolon after comments:
            MEMWBValue = 0; // or leave MEMWBValue as is
        end
    end

    assign mem_wb_bus_out.instruction = ex_mem_bus_in.instruction;
    assign mem_wb_bus_out.wb_value = MEMWBValue;
    assign mem_wb_bus_out.opcode = ex_mem_bus_in.opcode;
    assign mem_wb_bus_out.rd = ex_mem_bus_in.rd;

endmodule