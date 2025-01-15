`include "../core/utils/Opcodes.sv"
//`include "../../interfaces/ControlSignals.svh"
`include "../../interfaces/PipelineInterface.svh"

module ControlUnit(
    input wire id_ex_bus_t id_ex_bus_in,
    input wire  ex_mem_bus_t ex_mem_bus_in,
    input wire  mem_wb_bus_t mem_wb_bus_in,
    output logic takebranch,
    output logic [31:0] JalAddr
    //output control_signals_t ctrl_signals_out
);

    logic bypassAfromMEM, bypassBfromMEM;
    logic bypassAfromALUinWB, bypassBfromALUinWB;
    logic bypassAfromLDinWB, bypassBfromLDinWB;
    logic bypassDecodeAfromWB, bypassDecodeBfromWB;

    BypassUnit bypass_unit(
        .id_ex_bus_in(id_ex_bus_in),
        .ex_mem_bus_in(ex_mem_bus_in),
        .mem_wb_bus_in(mem_wb_bus_in),
        .bypassAfromMEM(bypassAfromMEM),
        .bypassBfromMEM(bypassBfromMEM),
        .bypassAfromALUinWB(bypassAfromALUinWB),
        .bypassBfromALUinWB(bypassBfromALUinWB),
        .bypassAfromLDinWB(bypassAfromLDinWB),
        .bypassBfromLDinWB(bypassBfromLDinWB),
        .bypassDecodeAfromWB(bypassDecodeAfromWB),
        .bypassDecodeBfromWB(bypassDecodeBfromWB)
    );
    


    logic takebranch_int;
    logic [31:0] A;
    logic [31:0] B;


    // Bypass done here because we need to set the control signals based on the bypassed values, that will be used in the next stage
    // Unlike the ALU Bypass, where the bypassed values are used in the same stage
    assign A = (bypassAfromMEM === 1'b1) ? ex_mem_bus_in.alu_result
             : ((bypassAfromALUinWB === 1'b1) || (bypassAfromLDinWB === 1'b1))
                ? mem_wb_bus_in.wb_value
                : id_ex_bus_in.decodeA;

    assign B = (bypassBfromMEM === 1'b1) ? ex_mem_bus_in.alu_result
             : ((bypassBfromALUinWB === 1'b1) || (bypassBfromLDinWB === 1'b1))
                ? mem_wb_bus_in.wb_value
                : id_ex_bus_in.decodeB;
                
    assign takebranch_int = ((id_ex_bus_in.opcode == BEQ) && (A == B)) || (id_ex_bus_in.opcode == JALR);
    assign JalAddr = A + id_ex_bus_in.imm_i;

    assign takebranch = takebranch_int;

endmodule
