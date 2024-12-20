`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

/*
typedef struct packed {
    logic [31:0] instruction;
    logic [31:0] decodeA;
    logic [31:0] decodeB;
    logic [31:0] branch_offset;
    // Pass opcode, rs1, rs2, rd, funct3, funct7 for EX usage
    logic [6:0]  opcode;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
} id_ex_bus_t;
*/

module PipelineRegs(
    input logic clock,
    input logic reset,
    input logic stall,
    input logic takebranch,

    input wire if_id_bus_t if_id_bus_in,
    output if_id_bus_t if_id_bus_out,

    input wire id_ex_bus_t id_ex_bus_in,
    output id_ex_bus_t id_ex_bus_out,

    input wire ex_mem_bus_t ex_mem_bus_in,
    output ex_mem_bus_t ex_mem_bus_out,

    input wire mem_wb_bus_t mem_wb_bus_in,
    output mem_wb_bus_t mem_wb_bus_out
);

    // For simplicity, if stall or branch, inject NOP instructions
    // NOP_INST defined in Opcodes.sv

    if_id_bus_t if_id_reg;
    id_ex_bus_t id_ex_reg;
    ex_mem_bus_t ex_mem_reg;
    mem_wb_bus_t mem_wb_reg;


    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            if_id_reg.instruction <= NOP_INST;
            id_ex_reg.instruction <= NOP_INST;
            ex_mem_reg.instruction <= NOP_INST;
            mem_wb_reg.instruction <= NOP_INST;

            //set all values to 0
            if_id_reg.rs1 <= 0;
            if_id_reg.rs2 <= 0;

            // Print pipeline registers on reset
            //$display("RESET: if_id_reg = %p, id_ex_reg = %p, ex_mem_reg = %p, mem_wb_reg = %p",if_id_reg, id_ex_reg, ex_mem_reg, mem_wb_reg);
        end else if (!stall) begin
            if (!takebranch) begin
                if_id_reg <= if_id_bus_in;
            end else begin
                if_id_reg.instruction <= NOP_INST;
            end
            id_ex_reg <= id_ex_bus_in;
             // Print pipeline registers on update
            //$display("UPDATE: if_id_reg = %p, id_ex_reg = %p, ex_mem_reg = %p, mem_wb_reg = %p",if_id_reg, id_ex_reg, ex_mem_reg, mem_wb_reg);
        end else begin
            // Stall: EXMEMIR <= NOP, don't update others
            id_ex_reg.instruction <= NOP_INST;
            // set all id ex values to respective NOP values
            id_ex_reg.rs1 <= 0;
            id_ex_reg.rs2 <= 0;
            id_ex_reg.rd <= 0;
            id_ex_reg.opcode <= 0;
            id_ex_reg.funct3 <= 0;
            id_ex_reg.funct7 <= 0;
            id_ex_reg.branch_offset <= 0;
            id_ex_reg.decodeA <= 0;
            id_ex_reg.decodeB <= 0;

            // Print stall condition
            //$display("STALL: if_id_reg = %p, id_ex_reg = %p, ex_mem_reg = %p, mem_wb_reg = %p",if_id_reg, id_ex_reg, ex_mem_reg, mem_wb_reg);
            // Keep others stable
        end
        mem_wb_reg <= mem_wb_bus_in;
        ex_mem_reg <= ex_mem_bus_in;
        
    end

    assign if_id_bus_out = if_id_reg;
    assign id_ex_bus_out = id_ex_reg;
    assign ex_mem_bus_out = ex_mem_reg;
    assign mem_wb_bus_out = mem_wb_reg;

endmodule
