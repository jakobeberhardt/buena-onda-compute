module RISCVCPU (
    input wire clock
);

// Instruction opcodes
parameter LW      = 7'b0000011;
parameter SW      = 7'b0100011;
parameter BEQ     = 7'b1100011;
parameter NOP     = 32'h00000013;
parameter ALUopR  = 7'b0110011; // R-type ALU operations
parameter ALUopI  = 7'b0010011; // I-type immediate ALU operations

// Registers and Pipeline Registers
reg [31:0] PC;
reg [31:0] Regs[0:31];
reg [31:0] IDEXA, IDEXB, EXMEMB, EXMEMALUOut, MEMWBValue;
reg [31:0] IMemory [0:9], DMemory [0:1023]; // Separate memories
reg [31:0] IFIDIR, IDEXIR, EXMEMIR, MEMWBIR;    // Pipeline registers

// Wire Definitions
wire [4:0]  IFIDrs1, IFIDrs2, MEMWBrd; // Register fields
wire [6:0]  IDEXop, EXMEMop, MEMWBop;  // Opcode fields
wire [31:0] Ain, Bin;                   // ALU inputs
wire [2:0]  IDEXfunct3;                 // funct3 field
wire [6:0]  IDEXfunct7;                 // funct7 field

// Assignments for pipeline register fields
assign IFIDrs1  = IFIDIR[19:15];          // rs1 field
assign IFIDrs2  = IFIDIR[24:20];          // rs2 field
assign IDEXop   = IDEXIR[6:0];            // Opcode
assign EXMEMop  = EXMEMIR[6:0];           // Opcode
assign MEMWBop  = MEMWBIR[6:0];           // Opcode
assign MEMWBrd  = MEMWBIR[11:7];          // rd field
assign IDEXfunct3 = IDEXIR[14:12];        // funct3 field
assign IDEXfunct7 = IDEXIR[31:25];        // funct7 field

// ALU Inputs
assign Ain = IDEXA;
assign Bin = (IDEXop == ALUopI || IDEXop == LW || IDEXop == SW)
             ? {{20{IDEXIR[31]}}, IDEXIR[31:20]} // Immediate value for I-type
             : IDEXB; // Register value for R-type

integer i; // Loop variable for initialization

// Initial Block
initial begin
    PC        = 0;
    IFIDIR    = NOP;
    IDEXIR    = NOP;
    EXMEMIR   = NOP;
    MEMWBIR   = NOP; // Initialize pipeline registers with NOP

    // Initialize registers to their indices to avoid undefined states
    for (i = 0; i <= 31; i = i + 1) begin
        Regs[i] = i;
    end
end

// Always block triggered on positive edge of the clock
always @(posedge clock) begin
    // Fetch Stage
    IFIDIR <= IMemory[PC >> 2];
    PC     <= PC + 4;

    // Decode Stage
    IDEXA  <= Regs[IFIDrs1];
    IDEXB  <= Regs[IFIDrs2];
    IDEXIR <= IFIDIR; // Pass Instruction Register

    // Execute Stage
    if (IDEXop == LW || IDEXop == SW || IDEXop == ALUopI) begin
        // Immediate instructions
        case (IDEXop)
            LW, SW: begin
                EXMEMALUOut <= IDEXA + {{20{IDEXIR[31]}}, IDEXIR[31:20]};
            end
            ALUopI: begin
                case (IDEXfunct3)
                    3'b000: EXMEMALUOut <= Ain + Bin; // ADDI
                    3'b010: EXMEMALUOut <= ($signed(Ain) < $signed(Bin)) ? 1 : 0; // SLTI
                    // Add more I-type immediate operations if needed
                    default: EXMEMALUOut <= 0;
                endcase
            end
            default: EXMEMALUOut <= 0;
        endcase
    end
    else if (IDEXop == ALUopR) begin
        // R-type instructions
        case ({IDEXfunct7, IDEXfunct3})
            {7'b0000000, 3'b000}: EXMEMALUOut <= Ain + Bin; // ADD
            {7'b0100000, 3'b000}: EXMEMALUOut <= Ain - Bin; // SUB
            {7'b0000000, 3'b111}: EXMEMALUOut <= Ain & Bin; // AND
            {7'b0000000, 3'b110}: EXMEMALUOut <= Ain | Bin; // OR
            {7'b0000000, 3'b010}: EXMEMALUOut <= ($signed(Ain) < $signed(Bin)) ? 1 : 0; // SLT
            // Add more R-type operations if needed
            default: EXMEMALUOut <= 0;
        endcase
    end
    else begin
        EXMEMALUOut <= 0;
    end

    EXMEMIR <= IDEXIR;
    EXMEMB  <= IDEXB; // Pass B register

    // Memory Stage
    if (EXMEMop == ALUopR || EXMEMop == ALUopI) begin
        MEMWBValue <= EXMEMALUOut; // Pass ALU result
    end
    else if (EXMEMop == LW) begin
        MEMWBValue <= DMemory[EXMEMALUOut >> 2];
    end
    else if (EXMEMop == SW) begin
        DMemory[EXMEMALUOut >> 2] <= EXMEMB; // Store operation
    end

    MEMWBIR <= EXMEMIR; // Pass Instruction Register

    // Write-Back Stage
    if (((MEMWBop == LW) || (MEMWBop == ALUopR) || (MEMWBop == ALUopI)) && (MEMWBrd != 0)) begin
        Regs[MEMWBrd] <= MEMWBValue; // Update register file
    end

    // Ensure x0 is always zero
    Regs[0] <= 0;
end

endmodule
