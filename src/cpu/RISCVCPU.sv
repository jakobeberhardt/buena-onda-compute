`define DEBUG 1 
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
    logic iMem_valid;
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

    logic [31:0] JalAddr;
    // Instantiate pipeline stages
    IF if_stage(
        .clock(clock),
        .reset(reset),
        .stall(ctrl_signals.stall),
        .takebranch(ctrl_signals.takebranch),
        .branch_offset(id_ex_bus_in.branch_offset),
        .id_ex_bus_in(id_ex_bus_in),
        .JalAddr(JalAddr),
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
        .id_ex_bus_in(id_ex_bus_in),
        .ex_mem_bus_in(ex_mem_bus_in),
        .mem_wb_bus_in(mem_wb_bus_in),
        .takebranch(takebranch),
        .JalAddr(JalAddr)
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
    logic [31:0] iCache_instr;    // instruction output from ICache to IF
    logic [31:0] iCache_memAddr;  // address from ICache to IMemory
    logic [31:0] iMem_data;       // data from IMemory back to ICache

    IMemory imem(
        .clock(clock),
        .reset(reset),
        .addr(iCache_memAddr),
        .dataOut(iMem_data),
        .mem_valid(iMem_valid)
    );

    ICache i_cache(
        .clock(clock),
        .reset(reset),
        .addr_in(if_stage.PC >> 2),
        .data_out(iCache_instr),
        // to/from IMemory
        .mem_addr(iCache_memAddr),
        .mem_dataOut(iMem_data),
        .mem_valid(iMem_valid)
    );
    assign if_id_bus_in.instruction = iCache_instr;

    
    DMemory dmem(
        .clock(clock),
        .op(ex_mem_bus_out.opcode),
        .addr(ex_mem_bus_out.alu_result >> 2),
        .writeData(ex_mem_bus_out.b_val),
        .readData(dmemData)
    );

    always_comb begin
        ctrl_signals.takebranch = takebranch;
        ctrl_signals.imem_stall = ~iMem_valid;
        ctrl_signals.stall      = stall | ~iMem_valid;
        if (`DEBUG) begin
            $display("Stalls----------------------------");
            $display("Time: %0t | DEBUG: stall signal = %0d", $time, ctrl_signals.stall);
            $display("                   takebranch   = %0d", ctrl_signals.takebranch);
            $display("                   inst valid   = %0d", ctrl_signals.imem_stall);
            $display("Stalls----------------------------");
        end
    end

    // Connect MEM stage logic to dmemData and mem_wb_bus_in
    // mem_wb_bus_in.wb_value = depends on ex_mem_bus_out.opcode:
    // if LW: mem_wb_bus_in.wb_value = dmemData
    // if ALU: wb_value = ex_mem_bus_out.alu_result
    // if SW: no write-back (0)

    // Similar for decodeA/decodeB from ID stage using regfile_out_rs1/rs2 and mem_wb_bus_out for bypass at decode.
    // Remove or comment out this block from RISCVCPU.sv
    


endmodule
