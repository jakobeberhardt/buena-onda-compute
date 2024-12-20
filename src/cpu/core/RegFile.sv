
`include "utils/Opcodes.sv"
`include "../../interfaces/PipelineInterface.svh"

module RegFile(
    input logic clock,
    input wire mem_wb_bus_t mem_wb_bus_in,
    output logic [31:0] regfile_out_rs1,
    output logic [31:0] regfile_out_rs2,
    input  logic [4:0] rs1_idx,
    input  logic [4:0] rs2_idx
);
    
    logic [31:0] Regs[0:31];

    integer i;
    initial begin
        for (i=0; i<32; i=i+1)
            Regs[i] = i;
    end

    always  @(posedge clock) begin
        if (((mem_wb_bus_in.opcode == LW) || (mem_wb_bus_in.opcode == ALUopR) || (mem_wb_bus_in.opcode == ALUopI))
            && (mem_wb_bus_in.rd != 0)) begin
            Regs[mem_wb_bus_in.rd] <= mem_wb_bus_in.wb_value;
            
        end
        Regs[0] <= 0;
    end

    always_comb begin
        if (((mem_wb_bus_in.opcode == LW) || (mem_wb_bus_in.opcode == ALUopR) || (mem_wb_bus_in.opcode == ALUopI))
            && (mem_wb_bus_in.rd != 0)) begin
            $display("Time: %0t | DEBUG: Writing to register %0d with value %0d", $time, mem_wb_bus_in.rd, mem_wb_bus_in.wb_value);
            
        end
        
    end


    assign regfile_out_rs1 = Regs[rs1_idx];
    assign regfile_out_rs2 = Regs[rs2_idx];

    // Debugging
    always_comb begin
        $display("RegFile----------------------------");
        $display("Time: %0t | DEBUG: regfile_out_rs1 = %0d", $time, regfile_out_rs1);
        $display("Time: %0t | DEBUG: regfile_out_rs2 = %0d", $time, regfile_out_rs2);
        $display("RegFile----------------------------");
    end

endmodule
