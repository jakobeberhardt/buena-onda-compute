`ifndef PIPELINE_INTERFACE_SVH
`define PIPELINE_INTERFACE_SVH

typedef struct packed {
    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
} if_id_bus_t;

typedef struct packed {
    logic [31:0] instruction;
    logic [31:0] decodeA;
    logic [31:0] decodeB;
    logic [31:0] branch_offset;
    // Pass opcode, rs1, rs2, rd, funct3, funct7 for EX usage
    logic [6:0]  opcode;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    //immidiate i, used in JALR
    logic [31:0] imm_i;
} id_ex_bus_t;

typedef struct packed {
    logic [31:0] instruction;
    logic [31:0] alu_result;
    logic [31:0] b_val;
    // Pass opcode, rd for MEM stage
    logic [6:0]  opcode;
    logic [4:0]  rd;
    logic [2:0]  funct3;
} ex_mem_bus_t;

typedef struct packed {
    logic [31:0] instruction;
    logic [31:0] wb_value;
    logic [6:0]  opcode;
    logic [4:0]  rd;
} mem_wb_bus_t;

`endif
