`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

module EX(
    input  logic clock,
    input  logic reset,
    input  wire  id_ex_bus_t id_ex_bus_in,
    input  wire  id_ex_bus_t id_ex_bus_in_mul,
    input  wire  mem_wb_bus_t mem_wb_bus_in,
    output wire ex_mem_bus_t ex_mem_bus_out,
    input wire ex_mem_bus_t ex_mem_bus_in,
    input bypassAfromMEM,
    input bypassBfromMEM,
    input bypassAfromALUinWB,
    input bypassBfromALUinWB,
    input bypassAfromLDinWB,
    input bypassBfromLDinWB,
    input wire  control_signals_t ctrl_signals_in,
    output logic stall_mul
    );





    // Bypass signals would come from BypassUnit - assume we have them wired in top-level
    // For completeness, we show how they'd be connected at top level. Here, assume inputs:
    logic [31:0] Ain, Bin;
    logic [31:0] BValue; // Value to get bypassed for SW
    

    ALUInputSelect alu_input_select(
        .clock(clock),
        .IDEXop(id_ex_bus_in.opcode),
        .IDEXIR(id_ex_bus_in.instruction),
        .IDEXA(id_ex_bus_in.decodeA),
        .IDEXB(id_ex_bus_in.decodeB),
        .EXMEMALUOut(ex_mem_bus_in.alu_result),
        .MEMWBValue(mem_wb_bus_in.wb_value),
        .bypassAfromMEM(bypassAfromMEM),
        .bypassAfromALUinWB(bypassAfromALUinWB),
        .bypassAfromLDinWB(bypassAfromLDinWB),
        .bypassBfromMEM(bypassBfromMEM),
        .bypassBfromALUinWB(bypassBfromALUinWB),
        .bypassBfromLDinWB(bypassBfromLDinWB),
        .Ain(Ain),
        .Bin(Bin),
        .BypassRs2SW(BValue)
    );

    logic [31:0] EXMEMALUOut;

    // Single-cycle ALU 
    logic [31:0] singleCycleALUResult;
    ALU alu(
        .clock(clock),
        .Ain(Ain),
        .Bin(Bin),
        .IDEXop(id_ex_bus_in.opcode),
        .IDEXfunct3(id_ex_bus_in.funct3),
        .IDEXfunct7(id_ex_bus_in.funct7),
        .EXMEMALUOut(singleCycleALUResult)
    );

    // MUL detection
    logic isMUL;
    // inside EX:

    logic [2:0] mul_stall_counter;
    logic startMulCycle;

    // detect isMUL combinationally
    assign isMUL = (id_ex_bus_in.opcode == ALUopR) &&
                (id_ex_bus_in.funct7 == 7'b0000001) &&
                (id_ex_bus_in.funct3 == 3'b000);

    // Immediately request stall if isMUL and we haven't started the counter yet
    // or if the counter is still > 0
    assign stall_mul = (isMUL && mul_stall_counter == 0) || (mul_stall_counter > 1);

    // On the rising edge
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            mul_stall_counter <= 3'd0;
        end else begin
            // if this is the first cycle of MUL detection
            if (isMUL && mul_stall_counter == 0) begin
                // start 4-cycle stall
                mul_stall_counter <= 3'd5;
            end else if (mul_stall_counter > 0) begin
                // counting down
                mul_stall_counter <= mul_stall_counter - 1;
            end
        end
    end

    

    // 5-stage MUL
    logic [31:0] mul_result;
    logic        mul_valid_out;
    logic        mul_stall_out;

    MUL mul_unit(
        .clock(clock),
        .reset(reset),
        .A_in(Ain),
        .B_in(Bin),
        .valid_in(isMUL),       // Begin multiply if it's MUL
        .result_out(mul_result),
        .valid_out(mul_valid_out),
        .stall_out(mul_stall_out)
    );

    always_comb begin
        if (isMUL && mul_valid_out)
            EXMEMALUOut = mul_result;   // final product once done
        else if (isMUL && stall_mul)
            EXMEMALUOut = 32'd0;        // still busy => hold 0
        else
            EXMEMALUOut = singleCycleALUResult;
    end


    //assign stall_mul = mul_stall_out;



    
    

    assign ex_mem_bus_out.instruction = id_ex_bus_in.instruction;
    assign ex_mem_bus_out.alu_result = EXMEMALUOut;
    // select bits if sb, sh or sw
    assign ex_mem_bus_out.b_val = (id_ex_bus_in.funct3 == SB_FUNCT3) ? {{24{BValue[7]}},  BValue[7:0]}  :  // Sign-extend 8 bits to 32 bits
                              (id_ex_bus_in.funct3 == SH_FUNCT3) ? {{16{BValue[15]}}, BValue[15:0]} :  // Sign-extend 16 bits to 32 bits
                            BValue;  // Use full 32 bits


    assign ex_mem_bus_out.opcode = id_ex_bus_in.opcode;
    assign ex_mem_bus_out.rd = id_ex_bus_in.rd;
    assign ex_mem_bus_out.funct3 = id_ex_bus_in.funct3;

    always @(posedge clock) begin

        if (`DEBUG) begin
            $display("EX After ALU: EXMEMALUOut = %h", EXMEMALUOut);
            //display if mul

            $display("Time %0t, Is mul %0d,EX MUL: result = %h, valid = %0d, stall = %0d",$time, isMUL, mul_result, mul_valid_out, stall_mul);
        end
    end

endmodule
