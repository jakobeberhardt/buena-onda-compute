
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module HazardUnit(
    input  wire id_ex_bus_t   id_ex_bus_in,
    input  wire ex_mem_bus_t ex_mem_bus_in,
    output logic stall
);

    logic load_use_hazard;
    always_comb begin
        load_use_hazard = (ex_mem_bus_in.opcode == LW) && (
            (((id_ex_bus_in.opcode == LW)) && (id_ex_bus_in.rs1 == ex_mem_bus_in.rd)) ||
            ((id_ex_bus_in.opcode == SW) && ((id_ex_bus_in.rs1 == ex_mem_bus_in.rd) || (id_ex_bus_in.rs2 == ex_mem_bus_in.rd))) ||
            (((id_ex_bus_in.opcode == ALUopR) || (id_ex_bus_in.opcode == ALUopI)) && 
             ((id_ex_bus_in.rs1 == ex_mem_bus_in.rd) || (id_ex_bus_in.rs2 == ex_mem_bus_in.rd))) ||
            ((id_ex_bus_in.opcode == JALR) && (id_ex_bus_in.rs1 == ex_mem_bus_in.rd)) ||
            ((id_ex_bus_in.opcode == BEQ) && ((id_ex_bus_in.rs1 == ex_mem_bus_in.rd)  || (id_ex_bus_in.rs2 == ex_mem_bus_in.rd)))
        );
    end

    assign stall = load_use_hazard;

    /*always_comb begin
        $display("HAZARD----------------------------");
        $display("Time: %0t | DEBUG: id_ex_bus_in = %p", $time, id_ex_bus_in);
        $display("Time: %0t | DEBUG: ex_mem_bus_in = %p", $time, ex_mem_bus_in);
        $display("Time: %0t | DEBUG: load_use_hazard = %b", $time, load_use_hazard);
        $display("HAZARD----------------------------");
    end*/



endmodule
