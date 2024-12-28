`ifndef CONTROL_SIGNALS_SVH
`define CONTROL_SIGNALS_SVH

typedef struct packed {
    logic stall;     
    logic takebranch;   
    logic imem_stall;   
} control_signals_t;

`endif
