`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module IF(
    input  logic clock,
    input  logic reset,
    input  logic stall,
    input  logic takebranch,
    input  logic [31:0] branch_offset,
    input  wire  id_ex_bus_t id_ex_bus_in,
    input logic [31:0] JalAddr,
    output if_id_bus_t if_id_bus_out
);

    logic [31:0] PC;
    // initial PC = 0;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            PC <= 0;
        end else if (!stall) begin
            if (takebranch) 
                if (id_ex_bus_in.opcode == JALR) 
                    PC <= JalAddr;
                else
                    PC <= (PC - 4) + branch_offset;
            else 
                PC <= PC + 4;
        end
    end


   always @(posedge clock) begin
        if (`DEBUG) begin
            $display("IF----------------------------");
            $display("Time: %0t | DEBUG: BEQ, PC = %0d, takebranch = %0d, branch_offset = %0d", $time, PC, takebranch, branch_offset);
            $display("Time: %0t | DEBUG: JALR, id_ex_bus_in.decodeA = %0d, id_ex_bus_in.imm_i = %0d", $time, id_ex_bus_in.decodeA, id_ex_bus_in.imm_i);
            $display("IF----------------------------");
        end
    end


    // Instruction fetched by IMemory at top-level
    // The top-level connects IMemory's dataOut to if_id_bus_out.instruction.
    // Here we just define the structure. Actual assignment done at top-level through wires.

endmodule
