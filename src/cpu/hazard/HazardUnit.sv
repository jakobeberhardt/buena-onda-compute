
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module HazardUnit(
    input  wire id_ex_bus_t   id_ex_bus_in,
    input  wire ex_mem_bus_t ex_mem_bus_in,
    input  wire ex_mem_bus_t ex_mem_bus_out,
    output logic stall,
    output logic [2:0] excpt_out
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

    always_comb begin
        //det exception values if unalined adress in memory access, overflow in addition or subtraction, or if invalid address
        if (ex_mem_bus_out.opcode === LW || ex_mem_bus_out.opcode === SW) begin
            if (ex_mem_bus_out.alu_result[1:0] !== 2'b00) begin
                excpt_out = UNALIGNED_ACCESS;
                $display("EX: Unaligned access exception %p",ex_mem_bus_out);
            end
        end else if (id_ex_bus_in.opcode === ALUopR && id_ex_bus_in.funct3 === DIV) begin
            if (id_ex_bus_in.decodeB === 0) begin
                excpt_out = DIVIDE_BY_ZERO;
            end
        end else begin
            excpt_out = NO_EXCEPTION;
        end
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
