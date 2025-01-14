`ifndef CONTROL_SIGNALS_SVH
`define CONTROL_SIGNALS_SVH

typedef struct packed {
    logic stall;     
    logic takebranch;   
    logic dcache_stall; 
    logic load_use_stall;
    logic stall_mul;
    logic [2:0] excpt_out; 
} control_signals_t;

`endif
