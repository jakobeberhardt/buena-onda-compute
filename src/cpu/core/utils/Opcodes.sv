parameter LW      = 7'b0000011;
parameter SW      = 7'b0100011;
parameter LB     =  7'b0000011;
parameter SB     =  7'b0100011;
parameter JALR   = 7'b1100111;
parameter BEQ     = 7'b1100011;
parameter NOP_INST= 32'h00000013;
parameter ALUopR  = 7'b0110011; // R-type
parameter ALUopI  = 7'b0010011; // I-type
parameter DRAIN_CACHE = 7'b1111111;

//funct3 values
parameter ADD     = 3'b000;
parameter SUB     = 3'b000;
parameter MUL     = 3'b000;

//funct7 values
parameter ADDSUB  = 7'b0000000;
parameter MULOP   = 7'b0000001;

//funct3 values
parameter LW_FUNCT3 = 3'b010;
parameter SW_FUNCT3 = 3'b010;
parameter LB_FUNCT3 = 3'b000;
parameter SB_FUNCT3 = 3'b000;
parameter LH_FUNCT3 = 3'b100;
parameter SH_FUNCT3 = 3'b100;
