`ifndef CONTROL_SIGNALS_SVH
`define CONTROL_SIGNALS_SVH

typedef struct packed {
    logic stall;     
    logic takebranch;   
    logic icache_stall;    
    logic dcache_stall; 
    logic load_use_stall;
} control_signals_t;

`endif
