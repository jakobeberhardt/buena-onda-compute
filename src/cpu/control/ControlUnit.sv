`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"
`include "../../interfaces/PipelineInterface.svh"

module ControlUnit(
    input wire  id_ex_bus_t id_ex_bus_in,
    input wire  ex_mem_bus_t ex_mem_bus_in,
    input wire  mem_wb_bus_t mem_wb_bus_in,
    output logic takebranch
    //output control_signals_t ctrl_signals_out
);

    

    // From original code:
    // takebranch = (IFIDop == BEQ) && (DecodeA == DecodeB).
    // But now we have decodeA, decodeB in id_ex_bus_in
    logic takebranch_int;
    assign takebranch_int = (id_ex_bus_in.opcode == BEQ) && (id_ex_bus_in.decodeA == id_ex_bus_in.decodeB);

    // Stall is computed by HazardUnit, so we leave ctrl_signals_out.stall as is:
    // We'll assume HazardUnit updates ctrl_signals_out via inout logic.

    assign takebranch = takebranch_int;

endmodule
