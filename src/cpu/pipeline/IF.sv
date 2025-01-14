`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module IF(
    input  logic clock,
    input  logic reset,
    input  logic stall,
    input  logic iCacheStall,   // <--- NEW: iCache stall signal
    input  logic takebranch,
    input  logic [31:0] branch_offset,
    input  wire  id_ex_bus_t id_ex_bus_in,
    input  logic [31:0] JalAddr,
    output if_id_bus_t if_id_bus_out,
    input wire logic [2:0] excpt_in
);

    logic [31:0] PC;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            PC <= INIT_ADDR;
        end else if (excpt_in) begin
            PC <= EXCPT_ADDR;
        end  
        else if (takebranch) begin
            // Handle branch or JALR
            if (id_ex_bus_in.opcode == JALR) 
                PC <= JalAddr;
            else
                PC <= (PC - 32'd4) + branch_offset;
        end 
        else if (!stall) begin
            // Normal pipeline not stalled by load-use or D‐cache
            // Check iCacheStall to freeze the PC on I‐cache miss
            if (iCacheStall)
                PC <= PC;          // freeze PC
            else
                PC <= PC + 32'd4;  // increment PC
        end
    end

    // Debug prints
    always_ff @(posedge clock) begin
        if (`DEBUG) begin
            $display("IF----------------------------");
            $display("Time: %0t | PC = %0d, takebranch = %0d, branch_offset = %0d",
                     $time, PC, takebranch, branch_offset);
            $display("Time: %0t | JALR? opcode=%0h, JalAddr=%0d", 
                     $time, id_ex_bus_in.opcode, JalAddr);
            $display("Time: %0t | iCacheStall=%0d, stall=%0d",
                     $time, iCacheStall, stall);
            $display("IF----------------------------");
        end
    end

    // The actual instruction fed to ID is handled at top-level by either:
    //   if_id_bus_in.instruction = iCacheStall ? 32'h00000013 : iCache_instr;
    // or a similar mux.  That way you can inject NOPs on iCacheStall.

endmodule
