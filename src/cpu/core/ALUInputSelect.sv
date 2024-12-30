`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "utils/Opcodes.sv"

module ALUInputSelect(
    input  logic clock,
    input  logic [6:0] IDEXop,
    input  logic [31:0] IDEXIR,
    input  logic [31:0] IDEXA,
    input  logic [31:0] IDEXB,
    input  logic [31:0] EXMEMALUOut,
    input  logic [31:0] MEMWBValue,
    input  logic bypassAfromMEM,
    input  logic bypassAfromALUinWB,
    input  logic bypassAfromLDinWB,
    input  logic bypassBfromMEM,
    input  logic bypassBfromALUinWB,
    input  logic bypassBfromLDinWB,
    output logic [31:0] Ain,
    output logic [31:0] Bin,
    output logic [31:0] BypassRs2SW // Value to get bypassed for SW
);


    logic [31:0] BypassB;
    assign Ain = (bypassAfromMEM === 1'b1) ? EXMEMALUOut
             : ((bypassAfromALUinWB === 1'b1) || (bypassAfromLDinWB === 1'b1))
                ? MEMWBValue
                : IDEXA;

    assign BypassB = (bypassBfromMEM === 1'b1) ? EXMEMALUOut :
                     ((bypassBfromALUinWB === 1'b1) || (bypassBfromLDinWB === 1'b1)) ? MEMWBValue
                    : IDEXB;

    assign BypassRs2SW = BypassB; // Value to get bypassed for SW

    logic [31:0] imm_i;  
    logic [31:0] imm_s;
    assign imm_i = {{20{IDEXIR[31]}}, IDEXIR[31:20]};
    assign imm_s = {{20{IDEXIR[31]}}, IDEXIR[31:25], IDEXIR[11:7]};

    assign Bin =
        (IDEXop == ALUopI || IDEXop == LW) ? imm_i :
        (IDEXop == SW)                    ? imm_s :
                                            BypassB;

    always @(posedge clock) begin
        if (`DEBUG) begin
            $display("ALUInputSelect: Ain = %h, Bin = %h", Ain, Bin);
            $display("  Bypass Signals: bypassAfromMEM = %b, bypassAfromALUinWB = %b, bypassAfromLDinWB = %b", 
                    bypassAfromMEM, bypassAfromALUinWB, bypassAfromLDinWB);
            $display("                 bypassBfromMEM = %b, bypassBfromALUinWB = %b, bypassBfromLDinWB = %b", 
                    bypassBfromMEM, bypassBfromALUinWB, bypassBfromLDinWB);
            $display("  Inputs: IDEXA = %h, IDEXB = %h, EXMEMALUOut = %h, MEMWBValue = %h, IDEXop = %h", 
                    IDEXA, IDEXB, EXMEMALUOut, MEMWBValue, IDEXop);
            $display("  Immediate Values: imm_i = %h, imm_s = %h", imm_i, imm_s);
            $display("  BypassB = %h", BypassB);
            $display("  IDEXIR = %h", IDEXIR);
        end
    end



endmodule
