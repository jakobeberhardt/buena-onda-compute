`include "../interfaces/PipelineInterface.svh"
`include "../cpu/core/utils/Opcodes.sv"
`include "../interfaces/ControlSignals.svh"

module RISCVCPU(
    input logic clock,
    input logic reset
);


    control_signals_t ctrl_signals;
    if_id_bus_t if_id_bus_in, if_id_bus_out;
    id_ex_bus_t id_ex_bus_in, id_ex_bus_out;
    ex_mem_bus_t ex_mem_bus_in, ex_mem_bus_out;
    mem_wb_bus_t mem_wb_bus_in, mem_wb_bus_out;
    logic bypassAfromMEM, bypassBfromMEM;
    logic bypassAfromALUinWB, bypassBfromALUinWB;
    logic bypassAfromLDinWB, bypassBfromLDinWB;
    logic bypassDecodeAfromWB, bypassDecodeBfromWB;
    logic takebranch;
    logic stall;
    initial stall = 0;
    initial takebranch = 0;
    initial bypassAfromMEM = 0;
    initial bypassBfromMEM = 0;
    initial bypassAfromALUinWB = 0;
    initial bypassBfromALUinWB = 0;
    initial bypassAfromLDinWB = 0;
    initial bypassBfromLDinWB = 0;
    initial bypassDecodeAfromWB = 0;
    initial bypassDecodeBfromWB = 0;

    initial mem_wb_bus_in.wb_value = 0;
    initial mem_wb_bus_in.opcode = 0;
    initial mem_wb_bus_in.rd = 0;

    // RegFile
    logic [31:0] regfile_out_rs1, regfile_out_rs2;
    RegFile regfile(
        .clock(clock),
        .mem_wb_bus_in(mem_wb_bus_out),
        .regfile_out_rs1(regfile_out_rs1),
        .regfile_out_rs2(regfile_out_rs2),
        .rs1_idx(id_ex_bus_in.rs1),
        .rs2_idx(id_ex_bus_in.rs2)
    );

    // Instantiate pipeline stages
    IF if_stage(
        .clock(clock),
        .reset(reset),
        .stall(ctrl_signals.stall),
        .takebranch(ctrl_signals.takebranch),
        .branch_offset(id_ex_bus_out.branch_offset),
        .if_id_bus_out(if_id_bus_in)
    );

    ID id_stage(
        .clock(clock),
        .reset(reset),
        .if_id_bus_in(if_id_bus_out),
        .mem_wb_bus_in(mem_wb_bus_out),
        .ctrl_signals_in(ctrl_signals),
        .RegsVal1(regfile_out_rs1),
        .RegsVal2(regfile_out_rs2),
        .id_ex_bus_out(id_ex_bus_in)
    );

    EX ex_stage(
        .clock(clock),
        .reset(reset),
        .id_ex_bus_in(id_ex_bus_out),
        .ex_mem_bus_out(ex_mem_bus_in),
        .ex_mem_bus_in(ex_mem_bus_out),
        .mem_wb_bus_in(mem_wb_bus_out),
        .bypassAfromMEM(bypassAfromMEM),
        .bypassBfromMEM(bypassBfromMEM),
        .bypassAfromALUinWB(bypassAfromALUinWB),
        .bypassBfromALUinWB(bypassBfromALUinWB),
        .bypassAfromLDinWB(bypassAfromLDinWB),
        .bypassBfromLDinWB(bypassBfromLDinWB),
        .ctrl_signals_in(ctrl_signals)
    );

    logic [31:0] dmemData;

    MEM mem_stage(
        .clock(clock),
        .reset(reset),
        .ex_mem_bus_in(ex_mem_bus_out),
        .dmemData(dmemData),
        .mem_wb_bus_out(mem_wb_bus_in)
    );

    WB wb_stage(
        .clock(clock),
        .reset(reset),
        .mem_wb_bus_in(mem_wb_bus_out),
        .ctrl_signals_in(ctrl_signals)
    );

    PipelineRegs pipeline_regs(
        .clock(clock),
        .reset(reset),
        .stall(ctrl_signals.stall),
        .takebranch(ctrl_signals.takebranch),
        .if_id_bus_in(if_id_bus_in), .if_id_bus_out(if_id_bus_out),
        .id_ex_bus_in(id_ex_bus_in), .id_ex_bus_out(id_ex_bus_out),
        .ex_mem_bus_in(ex_mem_bus_in), .ex_mem_bus_out(ex_mem_bus_out),
        .mem_wb_bus_in(mem_wb_bus_in), .mem_wb_bus_out(mem_wb_bus_out)
    );

    ControlUnit control_unit (
        .id_ex_bus_in(id_ex_bus_out),
        .ex_mem_bus_in(ex_mem_bus_out),
        .mem_wb_bus_in(mem_wb_bus_out),
        .takebranch(takebranch)
    );

    HazardUnit hazard_unit(
        .id_ex_bus_in(id_ex_bus_in),
        .ex_mem_bus_in(ex_mem_bus_in),
        .stall(stall)
    );

    //assign ctrl_signals.stall = stall;

    BypassUnit bypass_unit(
        .id_ex_bus_in(id_ex_bus_out),
        .ex_mem_bus_in(ex_mem_bus_out),
        .mem_wb_bus_in(mem_wb_bus_out),
        .bypassAfromMEM(bypassAfromMEM),
        .bypassBfromMEM(bypassBfromMEM),
        .bypassAfromALUinWB(bypassAfromALUinWB),
        .bypassBfromALUinWB(bypassBfromALUinWB),
        .bypassAfromLDinWB(bypassAfromLDinWB),
        .bypassBfromLDinWB(bypassBfromLDinWB),
        .bypassDecodeAfromWB(bypassDecodeAfromWB),
        .bypassDecodeBfromWB(bypassDecodeBfromWB)
    );

    

    // Memories
    logic [31:0] imemData;
    IMemory imem(
        .addr(if_stage.PC >> 2), // expose PC from IF stage if needed
        .dataOut(imemData)
    );
    assign if_id_bus_in.instruction = imemData;

    
    DMemory dmem(
        .clock(clock),
        .op(ex_mem_bus_out.opcode),
        .addr(ex_mem_bus_out.alu_result >> 2),
        .writeData(ex_mem_bus_out.b_val),
        .readData(dmemData)
    );

    always_comb begin
        ctrl_signals.takebranch = takebranch;
        ctrl_signals.stall      = stall;
    end

    // Connect MEM stage logic to dmemData and mem_wb_bus_in
    // mem_wb_bus_in.wb_value = depends on ex_mem_bus_out.opcode:
    // if LW: mem_wb_bus_in.wb_value = dmemData
    // if ALU: wb_value = ex_mem_bus_out.alu_result
    // if SW: no write-back (0)

    // Similar for decodeA/decodeB from ID stage using regfile_out_rs1/rs2 and mem_wb_bus_out for bypass at decode.
    // Remove or comment out this block from RISCVCPU.sv
    


endmodule
