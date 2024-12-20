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

    ALUInputSelect alu_input_select(
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
        .Bin(Bin)
    );

    logic [31:0] EXMEMALUOut;

    ALU alu(
        .Ain(Ain),
        .Bin(Bin),
        .IDEXop(id_ex_bus_in.opcode),
        .IDEXfunct3(id_ex_bus_in.funct3),
        .IDEXfunct7(id_ex_bus_in.funct7),
        .EXMEMALUOut(EXMEMALUOut)
    );

    assign ex_mem_bus_out.instruction = id_ex_bus_in.instruction;
    assign ex_mem_bus_out.alu_result = EXMEMALUOut;
    assign ex_mem_bus_out.b_val = id_ex_bus_in.decodeB;
    assign ex_mem_bus_out.opcode = id_ex_bus_in.opcode;
    assign ex_mem_bus_out.rd = id_ex_bus_in.rd;

    always_comb begin
        $display("EX After ALU: EXMEMALUOut = %h", EXMEMALUOut);
    end

endmodule