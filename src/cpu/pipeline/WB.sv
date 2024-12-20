`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module WB(
    input  logic clock,
    input  logic reset,
    input wire  mem_wb_bus_t mem_wb_bus_in,
    input wire  control_signals_t ctrl_signals_in
);
    // The actual register file write is done in RegFile on posedge clock
    // by checking mem_wb_bus_in fields. This stage is conceptually empty if RegFile writes on MEM/WB signal.
    // Just here to follow pipeline structure.
endmodule
