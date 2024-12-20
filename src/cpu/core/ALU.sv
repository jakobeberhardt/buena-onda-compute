`include "utils/Opcodes.sv"

module ALU(
    input  logic [31:0] Ain,
    input  logic [31:0] Bin,
    input  logic [6:0] IDEXop,
    input  logic [2:0] IDEXfunct3,
    input  logic [6:0] IDEXfunct7,
    output logic [31:0] EXMEMALUOut
);


    always_comb begin
        EXMEMALUOut = 0;
        if (IDEXop == LW || IDEXop == SW || IDEXop == ALUopI) begin
            case (IDEXop)
                LW, SW: EXMEMALUOut = Ain + Bin;
                ALUopI: begin
                    case (IDEXfunct3)
                        3'b000: EXMEMALUOut = Ain + Bin; 
                        3'b010: EXMEMALUOut = ($signed(Ain) < $signed(Bin)) ? 1 : 0;
                        default: EXMEMALUOut = 0;
                    endcase
                end
            endcase
        end else if (IDEXop == ALUopR) begin
            case ({IDEXfunct7, IDEXfunct3})
                {7'b0000000, 3'b000}: EXMEMALUOut = Ain + Bin;
                {7'b0100000, 3'b000}: EXMEMALUOut = Ain - Bin;
                {7'b0000000, 3'b111}: EXMEMALUOut = Ain & Bin;
                {7'b0000000, 3'b110}: EXMEMALUOut = Ain | Bin;
                {7'b0000000, 3'b010}: EXMEMALUOut = ($signed(Ain) < $signed(Bin)) ? 1 : 0;
                default: EXMEMALUOut = 0;
            endcase
        end
        $display("ALU Output: EXMEMALUOut = %h, Ain = %h, Bin = %h, IDEXop = %h, IDEXfunct3 = %b, IDEXfunct7 = %b", 
             EXMEMALUOut, Ain, Bin, IDEXop, IDEXfunct3, IDEXfunct7);
    end
endmodule
