`include "utils/Opcodes.sv"

module ALUInputSelect(
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
    output logic [31:0] Bin
);


    logic [31:0] BypassB;
    assign Ain = bypassAfromMEM ? EXMEMALUOut :
                 (bypassAfromALUinWB || bypassAfromLDinWB) ? MEMWBValue :
                 IDEXA;

    assign BypassB = bypassBfromMEM ? EXMEMALUOut :
                     (bypassBfromALUinWB || bypassBfromLDinWB) ? MEMWBValue :
                     IDEXB;

    assign Bin = (IDEXop == ALUopI || IDEXop == LW || IDEXop == SW) 
                 ? {{20{IDEXIR[31]}}, IDEXIR[31:20]} 
                 : BypassB;

    always_comb begin
        $display("ALUInputSelect: Ain = %h, Bin = %h", Ain, Bin);
        $display("  Bypass Signals: bypassAfromMEM = %b, bypassAfromALUinWB = %b, bypassAfromLDinWB = %b", 
                bypassAfromMEM, bypassAfromALUinWB, bypassAfromLDinWB);
        $display("                 bypassBfromMEM = %b, bypassBfromALUinWB = %b, bypassBfromLDinWB = %b", 
                bypassBfromMEM, bypassBfromALUinWB, bypassBfromLDinWB);
        $display("  Inputs: IDEXA = %h, IDEXB = %h, EXMEMALUOut = %h, MEMWBValue = %h, IDEXop = %h", 
                IDEXA, IDEXB, EXMEMALUOut, MEMWBValue, IDEXop);
    end



endmodule
