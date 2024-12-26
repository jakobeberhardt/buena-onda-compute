module ICache(
    input  logic        clock,
    input  logic        reset,
    input  logic [31:0] addr_in,     // CPU's requested PC
    output logic [31:0] data_out,    // Instruction to CPU/IF stage

    // interface to IMemory
    output logic [31:0] mem_addr,
    input  logic [31:0] mem_dataOut
);


    assign mem_addr  = addr_in;     // pass address to memory
    assign data_out  = mem_dataOut; // pass memory data out to CPU

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            // Initialize cache
        end
        else begin
            // real logic
        end
    end

endmodule
