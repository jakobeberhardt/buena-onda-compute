`define DEBUG 0 
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
    logic load_use_stall;
    logic dCacheStall;
    logic iCacheStall;
    logic stall_mul;
    logic [2:0] excpt;


    // RegFile
    logic [31:0] regfile_out_rs1, regfile_out_rs2;
    RegFile regfile(
        .clock(clock),
        .reset(reset),
        .mem_wb_bus_in(mem_wb_bus_out),
        .regfile_out_rs1(regfile_out_rs1),
        .regfile_out_rs2(regfile_out_rs2),
        .rs1_idx(id_ex_bus_in.rs1),
        .rs2_idx(id_ex_bus_in.rs2),
        .excpt_in(excpt),
        .excpt_inst_in(ex_mem_bus_out.instruction)
    );

    logic [31:0] JalAddr;
    // Instantiate pipeline stages
    IF if_stage(
        .clock(clock),
        .reset(reset),
        .stall(ctrl_signals.stall),
        .iCacheStall(iCacheStall),
        .takebranch(ctrl_signals.takebranch),
        .branch_offset(id_ex_bus_in.branch_offset),
        .id_ex_bus_in(id_ex_bus_in),
        .JalAddr(JalAddr),
        .if_id_bus_out(if_id_bus_in),
        .excpt_in(excpt)
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
        .id_ex_bus_in_mul(id_ex_bus_in),
        .ex_mem_bus_out(ex_mem_bus_in),
        .ex_mem_bus_in(ex_mem_bus_out),
        .mem_wb_bus_in(mem_wb_bus_out),
        .bypassAfromMEM(bypassAfromMEM),
        .bypassBfromMEM(bypassBfromMEM),
        .bypassAfromALUinWB(bypassAfromALUinWB),
        .bypassBfromALUinWB(bypassBfromALUinWB),
        .bypassAfromLDinWB(bypassAfromLDinWB),
        .bypassBfromLDinWB(bypassBfromLDinWB),
        .ctrl_signals_in(ctrl_signals),
        .stall_mul(stall_mul)
    );

    
    MEM mem_stage(
        .clock(clock),
        .reset(reset),
        .ex_mem_bus_in(ex_mem_bus_out),
        .mem_wb_bus_out(mem_wb_bus_in),
        .stall(dCacheStall),
        .excpt_in(excpt)
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
        .ctrl_signals(ctrl_signals),
        .if_id_bus_in(if_id_bus_in), .if_id_bus_out(if_id_bus_out),
        .id_ex_bus_in(id_ex_bus_in), .id_ex_bus_out(id_ex_bus_out),
        .ex_mem_bus_in(ex_mem_bus_in), .ex_mem_bus_out(ex_mem_bus_out),
        .mem_wb_bus_in(mem_wb_bus_in), .mem_wb_bus_out(mem_wb_bus_out),
        .excpt_in(excpt)
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
        .ex_mem_bus_out(ex_mem_bus_out),
        .stall(load_use_stall),
        .excpt_out(excpt)
    );

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
    logic [31:0] tlb_phys_addr;
    logic        iTLB_stall;
    ITLB i_tlb(
    .clock         (clock),
    .reset         (reset),
    .virt_addr_in  (if_stage.PC), 
    .phys_addr_out (tlb_phys_addr),
    .iTLB_stall    (iTLB_stall)
);


    logic [31:0] iCache_instr;    // instruction output from ICache to IF
    logic [31:0] iCache_memAddr;  // address from ICache to IMemory
    logic [127:0] iMem_data;       // data from IMemory back to ICache

    ICache i_cache(
    .clock       (clock),
    .reset       (reset),
    .addr_in     (tlb_phys_addr >> 2),
    .data_out    (iCache_instr),
    .iCache_stall(iCacheStall),
    .mem_addr    (iCache_memAddr),
    .mem_dataOut (iMem_data)
);

    IMemory imem(
        .addr(iCache_memAddr),
        .dataOut(iMem_data)
    );
    assign if_id_bus_in.instruction = iCacheStall ? 32'h00000013 : iCache_instr;

    
    //Set control signals
    always_comb begin
        ctrl_signals.takebranch    = takebranch;
        ctrl_signals.dcache_stall  = dCacheStall;
        ctrl_signals.load_use_stall= load_use_stall;
        ctrl_signals.stall_mul     = stall_mul;
        ctrl_signals.excpt_out     = excpt;
        ctrl_signals.stall         = load_use_stall | dCacheStall | stall_mul | iTLB_stall;
    end

    


    always_ff @(posedge clock) begin
        if (reset) begin
            bypassAfromMEM             <= 0;
            bypassBfromMEM             <= 0;
            bypassAfromALUinWB         <= 0;
            bypassBfromALUinWB         <= 0;
            bypassAfromLDinWB          <= 0;
            bypassBfromLDinWB          <= 0;
            bypassDecodeAfromWB        <= 0;
            bypassDecodeBfromWB        <= 0;
            takebranch                 <= 0;
            load_use_stall             <= 0;
            dCacheStall                <= 0;
            iCacheStall                <= 0;
            stall_mul                  <= 0;
            excpt                      <= 0;
        end
       if (`DEBUG) begin
            $display("Stalls----------------------------");
            $display("Time: %0t | DEBUG: stall signal = %0d", $time, ctrl_signals.stall);
            $display("                   takebranch   = %0d", ctrl_signals.takebranch);
            $display("                   dCache stall = %0d", dCacheStall);
            $display("                   load use stall = %0d", load_use_stall);
            $display("Stalls----------------------------");
        end
    end

endmodule
