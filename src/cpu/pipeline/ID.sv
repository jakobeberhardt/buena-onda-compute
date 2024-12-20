`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module ID(
    input  logic clock,
    input  logic reset,
    input  wire if_id_bus_t if_id_bus_in,
    input  wire mem_wb_bus_t mem_wb_bus_in,
    input  wire control_signals_t ctrl_signals_in,
    input logic [31:0] RegsVal1,
    input logic [31:0] RegsVal2,
    output id_ex_bus_t id_ex_bus_out
    
);

    // Decoder:
    logic [6:0]  IFIDop;
    logic [4:0]  IFIDrs1, IFIDrs2, IFIDrd;
    logic [2:0]  IFIDfunct3;
    logic [6:0]  IFIDfunct7;

    Decoder dec(
        .instruction(if_id_bus_in.instruction),
        .opcode(IFIDop), .rs1(IFIDrs1), .rs2(IFIDrs2), .rd(IFIDrd),
        .funct3(IFIDfunct3), .funct7(IFIDfunct7)
    );

    // RegFile read handled separately. We'll assume RegFile is global and we have access via functions or top-level wiring.
    // Original code: DecodeA, DecodeB = Regs[IFIDrs1], Regs[IFIDrs2] or WB value if bypassDecode?
    // We'll replicate original logic in RegFile or top-level. For simplicity assume RegFile provides RegsValue via a function.
    // Actually, we must do bypassDecodeAfromWB, bypassDecodeBfromWB:
    // from original:
    // DecodeA = bypassDecodeAfromWB ? MEMWBValue : Regs[IFIDrs1]
    // DecodeB = bypassDecodeBfromWB ? MEMWBValue : Regs[IFIDrs2]

    // We'll assume top-level or RegFile handles bypass at decode. For simplicity, let's say:
    logic [31:0] DecodeA, DecodeB;
    // A real implementation: We'll have RegFile as a separate module with outputs for IFIDrs1, IFIDrs2.
    // For now, let's store register logic in RegFile module and have signals provided to ID via global wires (not shown for brevity).
    // In a real scenario, you'd connect RegFile outputs here. Let's assume we have tasks:
    //import "DPI-C" function int get_reg_val(input int r); // Just conceptual

    always_comb begin
        // In actual code, connect RegsVal1 = RegFile output for IFIDrs1
        // RegsVal1 and RegsVal2 should be wired from RegFile. Assume RegFile is updated in WB stage.
        // Suppose we have a global array Regs accessible or top-level connecting them:
        // For correctness, let's define a separate approach:
        DecodeA = (mem_wb_bus_in.rd == IFIDrs1 && mem_wb_bus_in.rd != 0 &&
                   ((mem_wb_bus_in.opcode == ALUopR)||(mem_wb_bus_in.opcode==ALUopI)||(mem_wb_bus_in.opcode==LW)))
                  ? mem_wb_bus_in.wb_value : RegsVal1;

        DecodeB = (mem_wb_bus_in.rd == IFIDrs2 && mem_wb_bus_in.rd != 0 && ((mem_wb_bus_in.opcode == ALUopR)||(mem_wb_bus_in.opcode==ALUopI)||(mem_wb_bus_in.opcode==LW)))
                  ? mem_wb_bus_in.wb_value : RegsVal2;
    end

    // Branch offset:
    logic [31:0] branch_offset;
    assign branch_offset = {{20{if_id_bus_in.instruction[31]}},
                            if_id_bus_in.instruction[31],
                            if_id_bus_in.instruction[7],
                            if_id_bus_in.instruction[30:25],
                            if_id_bus_in.instruction[11:8], 1'b0};

    assign id_ex_bus_out.instruction = if_id_bus_in.instruction;
    assign id_ex_bus_out.decodeA = DecodeA;
    assign id_ex_bus_out.decodeB = DecodeB;
    assign id_ex_bus_out.branch_offset = branch_offset;
    assign id_ex_bus_out.opcode = IFIDop;
    assign id_ex_bus_out.rs1 = IFIDrs1;
    assign id_ex_bus_out.rs2 = IFIDrs2;
    assign id_ex_bus_out.rd  = IFIDrd;
    assign id_ex_bus_out.funct3 = IFIDfunct3;
    assign id_ex_bus_out.funct7 = IFIDfunct7;

    always_comb begin
        $display("ID----------------------------");
        $display("Time: %0t | DEBUG: id_ex_bus_out = %p", $time, id_ex_bus_out);
        $display("Time: %0t | DEBUG: mem_value = %d, Regval1 = %d , RegVal2 = %d", $time, mem_wb_bus_in.wb_value,RegsVal1,RegsVal2 );
        $display("Time: %0t | DEBUG: mem_wb_bus_in = %p,", $time, mem_wb_bus_in);
        $display("Time: %0t | DEBUG: DecodeA = %d, DecodeB = %d", $time, DecodeA,DecodeB );
        $display("Time: %0t | DEBUG: IFIDrs1 = %d, IFIDrs2 = %d, IFIDrd = %d", $time, IFIDrs1, IFIDrs2, IFIDrd);
        $display("ID----------------------------");
    end

endmodule
