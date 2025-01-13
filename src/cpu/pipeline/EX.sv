`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module EX(
    input  logic clock,
    input  logic reset,
    input  wire  id_ex_bus_t id_ex_bus_in,
    input  wire  mem_wb_bus_t mem_wb_bus_in,
    output wire ex_mem_bus_t ex_mem_bus_out,
    input wire ex_mem_bus_t ex_mem_bus_in,
    input bypassAfromMEM,
    input bypassBfromMEM,
    input bypassAfromALUinWB,
    input bypassBfromALUinWB,
    input bypassAfromLDinWB,
    input bypassBfromLDinWB,
    input wire  control_signals_t ctrl_signals_in
);


    // Bypass signals would come from BypassUnit - assume we have them wired in top-level
    // For completeness, we show how they'd be connected at top level. Here, assume inputs:
    logic [31:0] Ain, Bin;
    logic [31:0] BValue; // Value to get bypassed for SW

    ALUInputSelect alu_input_select(
        .clock(clock),
        .IDEXop(id_ex_bus_in.opcode),
        .IDEXIR(id_ex_bus_in.instruction),
        .IDEXA(id_ex_bus_in.decodeA),
        .IDEXB(id_ex_bus_in.decodeB),
        .EXMEMALUOut(ex_mem_bus_in.alu_result),
        .MEMWBValue(mem_wb_bus_in.wb_value),
        .bypassAfromMEM(bypassAfromMEM),
        .bypassAfromALUinWB(bypassAfromALUinWB),
        .bypassAfromLDinWB(bypassAfromLDinWB),
        .bypassBfromMEM(bypassBfromMEM),
        .bypassBfromALUinWB(bypassBfromALUinWB),
        .bypassBfromLDinWB(bypassBfromLDinWB),
        .Ain(Ain),
        .Bin(Bin),
        .BypassRs2SW(BValue)
    );

    logic [31:0] EXMEMALUOut;

    ALU alu(
        .clock(clock),
        .Ain(Ain),
        .Bin(Bin),
        .IDEXop(id_ex_bus_in.opcode),
        .IDEXfunct3(id_ex_bus_in.funct3),
        .IDEXfunct7(id_ex_bus_in.funct7),
        .EXMEMALUOut(EXMEMALUOut)
    );

    

    assign ex_mem_bus_out.instruction = id_ex_bus_in.instruction;
    assign ex_mem_bus_out.alu_result = EXMEMALUOut;
    // select bits if sb, sh or sw
    assign ex_mem_bus_out.b_val = (id_ex_bus_in.funct3 == SB_FUNCT3) ? {{24{BValue[7]}},  BValue[7:0]}  :  // Sign-extend 8 bits to 32 bits
                              (id_ex_bus_in.funct3 == SH_FUNCT3) ? {{16{BValue[15]}}, BValue[15:0]} :  // Sign-extend 16 bits to 32 bits
                            BValue;  // Use full 32 bits


    assign ex_mem_bus_out.opcode = id_ex_bus_in.opcode;
    assign ex_mem_bus_out.rd = id_ex_bus_in.rd;
    assign ex_mem_bus_out.funct3 = id_ex_bus_in.funct3;

    always @(posedge clock) begin
        if (`DEBUG) begin
            //$display("EX After ALU: EXMEMALUOut = %h", EXMEMALUOut);
        end
    end

endmodule
