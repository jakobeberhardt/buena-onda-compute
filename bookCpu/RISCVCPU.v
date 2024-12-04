module RISCVCPU (clock);
    // Instruction opcodes
    parameter LW    = 7'b000_0011,
              SW    = 7'b010_0011,
              BEQ   = 7'b110_0011,
              NOP   = 32'h0000_0013,
              ALUop = 7'b001_0011;

    input clock;

    reg [31:0] PC, Regs[0:31], IDEXA, IDEXB, EXMEMB, EXMEMALUOut, MEMWBValue;
    reg [31:0] IMemory[0:1023], DMemory[0:1023]; // Separate memories
    reg [31:0] IFIDIR, IDEXIR, EXMEMIR, MEMWBIR; // Pipeline registers

    wire [4:0] IFIDrs1, IFIDrs2, IDEXrs1, IDEXrs2, EXMEMrd, MEMWBrd; // Access register fields
    wire [6:0] IFIDop, IDEXop, EXMEMop, MEMWBop; // Access opcodes
    wire [31:0] Ain, Bin; // ALU inputs

    // Declare the bypass signals
    wire bypassAfromMEM, bypassAfromALUinWB, bypassBfromMEM, bypassBfromALUinWB;
    wire bypassAfromLDinWB, bypassBfromLDinWB;
    wire stall;        // Stall signal
    wire takebranch;   // Branch signal

    assign IFIDop  = IFIDIR[6:0];
    assign IFIDrs1 = IFIDIR[19:15];
    assign IFIDrs2 = IFIDIR[24:20];

    assign IDEXop  = IDEXIR[6:0];
    assign IDEXrs1 = IDEXIR[19:15];
    assign IDEXrs2 = IDEXIR[24:20];

    assign EXMEMop = EXMEMIR[6:0];
    assign EXMEMrd = EXMEMIR[11:7];

    assign MEMWBop = MEMWBIR[6:0];
    assign MEMWBrd = MEMWBIR[11:7];

    // The bypass to input A from the MEM stage for an ALU operation
    assign bypassAfromMEM = (IDEXrs1 == EXMEMrd) && (IDEXrs1 != 0) && (EXMEMop == ALUop);

    // The bypass to input B from the MEM stage for an ALU operation
    assign bypassBfromMEM = (IDEXrs2 == EXMEMrd) && (IDEXrs2 != 0) && (EXMEMop == ALUop);

    // The bypass to input A from the WB stage for an ALU operation
    assign bypassAfromALUinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && (MEMWBop == ALUop);

    // The bypass to input B from the WB stage for an ALU operation
    assign bypassBfromALUinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && (MEMWBop == ALUop);

    // The bypass to input A from the WB stage for an LW operation
    assign bypassAfromLDinWB = (IDEXrs1 == MEMWBrd) && (IDEXrs1 != 0) && (MEMWBop == LW);

    // The bypass to input B from the WB stage for an LW operation
    assign bypassBfromLDinWB = (IDEXrs2 == MEMWBrd) && (IDEXrs2 != 0) && (MEMWBop == LW);

    // The A input to the ALU is bypassed from MEM if there is a bypass there,
    // otherwise from WB if there is a bypass there, and otherwise comes from the IDEX register
    assign Ain = bypassAfromMEM ? EXMEMALUOut :
                 (bypassAfromALUinWB || bypassAfromLDinWB) ? MEMWBValue :
                 IDEXA;

    // The B input to the ALU is bypassed from MEM if there is a bypass there,
    // otherwise from WB if there is a bypass there, and otherwise comes from the IDEX register
    assign Bin = bypassBfromMEM ? EXMEMALUOut :
                 (bypassBfromALUinWB || bypassBfromLDinWB) ? MEMWBValue :
                 IDEXB;

    // The signal for detecting a stall based on the use of a result from LW
    assign stall = (MEMWBop == LW) && ( // Source instruction is a load
                  (((IDEXop == LW) || (IDEXop == SW)) && (IDEXrs1 == MEMWBrd)) || // Stall for address calc
                  ((IDEXop == ALUop) && ((IDEXrs1 == MEMWBrd) || (IDEXrs2 == MEMWBrd)))); // ALU use

    // Signal for a taken branch: instruction is BEQ and registers are equal
    assign takebranch = (IFIDop == BEQ) && (Regs[IFIDrs1] == Regs[IFIDrs2]);

    integer i; // Used to initialize registers

    initial begin
        PC = 0;
        IFIDIR  = NOP;
        IDEXIR  = NOP;
        EXMEMIR = NOP;
        MEMWBIR = NOP; // Put NOPs in pipeline registers
        for (i = 0; i <= 31; i = i + 1)
            Regs[i] = i; // Initialize registers—just so they aren't cares
    end

    // Remember that ALL these actions happen every pipe stage and with the use of <= they happen in parallel!
    always @(posedge clock) begin
        if (~stall) begin // The first three pipeline stages stall if there is a load hazard
            if (~takebranch) begin // First instruction in the pipeline is being fetched normally
                IFIDIR <= IMemory[PC >> 2];
                PC     <= PC + 4;
            end else begin // A taken branch is in ID; instruction in IF is wrong; insert a NOP and reset the PC
                IFIDIR <= NOP;
                PC     <= PC + {{52{IFIDIR[31]}}, IFIDIR[7], IFIDIR[30:25], IFIDIR[11:8], 1'b0};
            end
            // Second instruction in pipeline is fetching registers
            IDEXA  <= Regs[IFIDrs1];
            IDEXB  <= Regs[IFIDrs2]; // Get two registers
            IDEXIR <= IFIDIR;        // Pass along IR—can happen anywhere, since this affects next stage only!
            // Third instruction is doing address calculation or ALU operation
            if (IDEXop == LW)
                EXMEMALUOut <= IDEXA + {{53{IDEXIR[31]}}, IDEXIR[30:20]};
            else if (IDEXop == SW)
                EXMEMALUOut <= IDEXA + {{53{IDEXIR[31]}}, IDEXIR[30:25], IDEXIR[11:7]};
            else if (IDEXop == ALUop)
                case (IDEXIR[31:25]) // Case for the various R-type instructions
                    7'b000_0000: EXMEMALUOut <= Ain + Bin; // ADD operation
                    default: ; // Other R-type operations: SUB, SLT, etc.
                endcase
            EXMEMIR <= IDEXIR;
            EXMEMB  <= IDEXB; // Pass along the IR & B register
        end else begin
            EXMEMIR <= NOP; // Freeze first three stages of pipeline; inject a NOP into the EX output
        end

        // MEM stage of pipeline
        if (EXMEMop == ALUop)
            MEMWBValue <= EXMEMALUOut; // Pass along ALU result
        else if (EXMEMop == LW)
            MEMWBValue <= DMemory[EXMEMALUOut >> 2];
        else if (EXMEMop == SW)
            DMemory[EXMEMALUOut >> 2] <= EXMEMB; // Store
        MEMWBIR <= EXMEMIR; // Pass along IR

        // WB stage
        if (((MEMWBop == LW) || (MEMWBop == ALUop)) && (MEMWBrd != 0)) // Update registers if load/ALU operation and destination not 0
            Regs[MEMWBrd] <= MEMWBValue;
    end
endmodule
