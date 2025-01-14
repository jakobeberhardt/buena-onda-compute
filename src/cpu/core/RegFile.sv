`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "utils/Opcodes.sv"
`include "../../interfaces/PipelineInterface.svh"

module RegFile(
    input logic clock,
    input logic reset,
    input wire mem_wb_bus_t mem_wb_bus_in,
    output logic [31:0] regfile_out_rs1,
    output logic [31:0] regfile_out_rs2,
    input  logic [4:0] rs1_idx,
    input  logic [4:0] rs2_idx,
    input logic [2:0] excpt_in,
    input [31:0] excpt_inst_in
);
    
    logic [31:0] Regs[0:31];
    logic [31:0] excpt_inst;
    logic [2:0] excpt_type;

    integer i;
    initial begin
        for (i=0; i<32; i=i+1)
            Regs[i] = i;
    end

    always  @(posedge clock) begin
        /*if (reset) begin
            Regs[0] <= 0;
            for (i=1; i<32; i=i+1)
                Regs[i] <= 0;
        end else*/if (excpt_in) begin
            excpt_inst <= excpt_inst_in;
            excpt_type <= excpt_in;
        end else if (((mem_wb_bus_in.opcode == LW) || (mem_wb_bus_in.opcode == ALUopR) || (mem_wb_bus_in.opcode == ALUopI))
            && (mem_wb_bus_in.rd != 0)) begin
            Regs[mem_wb_bus_in.rd] <= mem_wb_bus_in.wb_value;
        end
        Regs[0] <= 0;
    end

    always @(posedge clock) begin
        if (`DEBUG) begin
            if (((mem_wb_bus_in.opcode == LW) || (mem_wb_bus_in.opcode == ALUopR) || (mem_wb_bus_in.opcode == ALUopI))
                && (mem_wb_bus_in.rd != 0)) begin
                $display("Time: %0t | DEBUG: Writing to register %0d with value %0d", $time, mem_wb_bus_in.rd, mem_wb_bus_in.wb_value);      
            end
        end
    end


    assign regfile_out_rs1 = Regs[rs1_idx];
    assign regfile_out_rs2 = Regs[rs2_idx];

endmodule
