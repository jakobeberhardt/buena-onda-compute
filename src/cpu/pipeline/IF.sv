`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module IF(
    input  logic clock,
    input  logic reset,
    input  logic stall,
    input  logic takebranch,
    input  logic [31:0] branch_offset,
    output if_id_bus_t if_id_bus_out
);

    logic [31:0] PC;
    // initial PC = 0;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            PC <= 0;
        end else if (!stall) begin
            if (takebranch) 
                PC <= (PC - 4) + branch_offset;
            else 
                PC <= PC + 4;
        end
    end


   /* always_comb begin
        $display("IF----------------------------");
        $display("Time: %0t | DEBUG: if_id_bus_out = %p", $time, if_id_bus_out);
        $display("IF----------------------------");
    end*/


    // Instruction fetched by IMemory at top-level
    // The top-level connects IMemory's dataOut to if_id_bus_out.instruction.
    // Here we just define the structure. Actual assignment done at top-level through wires.

endmodule
