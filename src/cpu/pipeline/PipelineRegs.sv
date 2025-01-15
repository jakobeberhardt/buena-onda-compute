`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"


module PipelineRegs(
    input logic clock,
    input logic reset,
    input wire control_signals_t ctrl_signals,

    input wire if_id_bus_t if_id_bus_in,
    output if_id_bus_t if_id_bus_out,

    input wire id_ex_bus_t id_ex_bus_in,
    output id_ex_bus_t id_ex_bus_out,

    input wire ex_mem_bus_t ex_mem_bus_in,
    output ex_mem_bus_t ex_mem_bus_out,

    input wire mem_wb_bus_t mem_wb_bus_in,
    output mem_wb_bus_t mem_wb_bus_out,

    input logic [2:0] excpt_in
);


    if_id_bus_t if_id_reg;
    id_ex_bus_t id_ex_reg;
    ex_mem_bus_t ex_mem_reg;
    mem_wb_bus_t mem_wb_reg;


    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            if_id_reg <= if_id_nop;
            id_ex_reg <= id_ex_nop;
            ex_mem_reg <= ex_mem_nop;
            mem_wb_reg <= mem_wb_nop;
        end
        else if (excpt_in) begin
            // Handle Exceptions
            if_id_reg <= if_id_nop;
            id_ex_reg <= id_ex_nop;
            ex_mem_reg <= ex_mem_nop;
            mem_wb_reg <= ex_mem_bus_in;

        end else if (ctrl_signals.stall_mul) begin
            mem_wb_reg <= mem_wb_bus_in;

        end else if (ctrl_signals.takebranch && !ctrl_signals.stall) begin
            // Inject NOP into IF/ID to flush the instruction fetched after the branch
            if_id_reg <= if_id_nop;

            // Allow other pipeline stages to proceed normally
            id_ex_reg <= id_ex_bus_in;
            ex_mem_reg <= ex_mem_bus_in;
            mem_wb_reg <= mem_wb_bus_in;

        end else if (ctrl_signals.dcache_stall) begin
            // Handle Data Cache Stall
            mem_wb_reg <= mem_wb_reg;

        end else if (ctrl_signals.load_use_stall) begin
            // Handle Load Stall
            // Inject NOP into ID/EX to create a bubble
            id_ex_reg <= id_ex_nop;

            // EX/MEM and MEM/WB stages proceed normally
            ex_mem_reg <= ex_mem_bus_in;
            mem_wb_reg <= mem_wb_bus_in;

        end else begin
            // Normal Pipeline Operation: Update all pipeline stages
            if_id_reg <= if_id_bus_in;
            id_ex_reg <= id_ex_bus_in;
            ex_mem_reg <= ex_mem_bus_in;
            mem_wb_reg <= mem_wb_bus_in;
        end
    end

    assign if_id_bus_out = if_id_reg;
    assign id_ex_bus_out = id_ex_reg;
    assign ex_mem_bus_out = ex_mem_reg;
    assign mem_wb_bus_out = mem_wb_reg;

endmodule
