`ifndef PIPELINE_INTERFACE_SVH
`define PIPELINE_INTERFACE_SVH


parameter int TAGMSB = 19;
parameter int TAGLSB = 6;

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
    // immediate i, used in JALR
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

// --------------------------------------------------------------------
// data structure for cache tag
typedef struct packed {
    bit valid;                        // valid bit
    bit dirty;                        // dirty bit
    bit [TAGMSB:TAGLSB] tag;         // tag bits
} cache_tag_type;

// --------------------------------------------------------------------
// data structure for cache memory request
typedef struct packed {               // Changed to packed
    bit [1:0] index;   // 2-bit index
    bit       we;      // write enable
} cache_req_type;

// --------------------------------------------------------------------
// 128-bit cache line data
typedef bit [127:0] cache_data_type;

// --------------------------------------------------------------------
// data structures for CPU <-> Cache controller interface

// CPU request (CPU->cache controller)
typedef struct packed {               // Changed to packed
    bit [19:0] addr;   // 20-bit request addr
    bit [31:0] data;   // 32-bit request data (used when write)
    bit        rw;     // request type : 0 = read, 1 = write
    bit        valid;  // request is valid
} cpu_req_type;

// Cache result (cache controller->cpu)
typedef struct packed {               // Changed to packed
    bit [31:0] data;   // 32-bit data
    bit        ready;  // result is ready
} cpu_result_type;

// --------------------------------------------------------------------
// data structures for cache controller <-> memory interface

// memory request (cache controller->memory)
typedef struct packed {               // Changed to packed
    bit [20:0]    addr;  // request byte addr
    bit [127:0]   data;  // 128-bit request data (used when write)
    bit           rw;    // request type : 0 = read, 1 = write
    bit           valid; // request is valid
} mem_req_type;

// memory controller response (memory -> cache controller)
typedef struct packed {               // Changed to packed
    cache_data_type data;   // 128-bit read-back data
    bit             ready;  // data is ready
} mem_data_type;


//stage NOPS
id_ex_bus_t id_ex_nop = '{32'h0, 32'h0, 32'h0, 32'h0, 7'b0, 5'b0, 5'b0, 5'b0, 3'b0, 7'b0, 32'h0};
ex_mem_bus_t ex_mem_nop = '{32'h0, 32'h0, 32'h0, 7'b0, 5'b0, 3'b0};
mem_wb_bus_t mem_wb_nop = '{32'h0, 32'h0, 7'b0, 5'b0};
if_id_bus_t if_id_nop = '{32'h0, 7'b0, 5'b0, 5'b0};

`endif
