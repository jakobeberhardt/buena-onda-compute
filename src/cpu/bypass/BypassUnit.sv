// Include the interfaces and opcodes BEFORE the module definition
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"

module BypassUnit(
    input wire  id_ex_bus_t   id_ex_bus_in,
    input wire  ex_mem_bus_t  ex_mem_bus_in,
    input wire  mem_wb_bus_t  mem_wb_bus_in,
    output logic         bypassAfromMEM,
    output logic         bypassBfromMEM,
    output logic         bypassAfromALUinWB,
    output logic         bypassBfromALUinWB,
    output logic         bypassAfromLDinWB,
    output logic         bypassBfromLDinWB,
    output logic         bypassDecodeAfromWB,
    output logic         bypassDecodeBfromWB
);

    assign bypassAfromMEM = (id_ex_bus_in.rs1 == ex_mem_bus_in.rd) && (id_ex_bus_in.rs1 != 0) &&
                            ((ex_mem_bus_in.opcode == ALUopR) || (ex_mem_bus_in.opcode == ALUopI) || (ex_mem_bus_in.opcode == SW));

    assign bypassBfromMEM = (id_ex_bus_in.rs2 == ex_mem_bus_in.rd) && (id_ex_bus_in.rs2 != 0) &&
                            ((ex_mem_bus_in.opcode == ALUopR) || (ex_mem_bus_in.opcode == ALUopI) || (ex_mem_bus_in.opcode == SW));

    assign bypassAfromALUinWB = (id_ex_bus_in.rs1 == mem_wb_bus_in.rd) && (id_ex_bus_in.rs1 != 0) &&
                                ((mem_wb_bus_in.opcode == ALUopR) || (mem_wb_bus_in.opcode == ALUopI) || (mem_wb_bus_in.opcode == SW));

    assign bypassBfromALUinWB = (id_ex_bus_in.rs2 == mem_wb_bus_in.rd) && (id_ex_bus_in.rs2 != 0) &&
                                ((mem_wb_bus_in.opcode == ALUopR) || (mem_wb_bus_in.opcode == ALUopI) || (mem_wb_bus_in.opcode == SW));

    assign bypassAfromLDinWB = (id_ex_bus_in.rs1 == mem_wb_bus_in.rd) && (id_ex_bus_in.rs1 != 0) &&
                               (mem_wb_bus_in.opcode == LW);

    assign bypassBfromLDinWB = (id_ex_bus_in.rs2 == mem_wb_bus_in.rd) && (id_ex_bus_in.rs2 != 0) &&
                               (mem_wb_bus_in.opcode == LW);


endmodule
