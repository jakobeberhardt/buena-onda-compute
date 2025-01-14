module ICache(
    input  logic         clock,
    input  logic         reset,
    input  logic [31:0]  addr_in,   
    output logic [31:0]  data_out,
    output logic         iCache_stall,
    output logic [31:0]  mem_addr,
    input  logic [127:0] mem_dataOut
);

    assign iCache_stall = 0;
    // Send a line-aligned address to memory.
    assign mem_addr = (addr_in & 32'hFFFFFFFC);  
    logic [1:0] word_offset;
    assign word_offset = addr_in[1:0];

    always_comb begin
        // Word 0 of the line is in mem_dataOut[ 31 : 0 ]
        // Word 1 of the line is in mem_dataOut[ 63 : 32 ]
        // Word 2 of the line is in mem_dataOut[ 95 : 64 ]
        // Word 3 of the line is in mem_dataOut[127 : 96 ]
        unique case (word_offset)
            2'd3: data_out = mem_dataOut[ 31:  0];
            2'd2: data_out = mem_dataOut[ 63: 32];
            2'd1: data_out = mem_dataOut[ 95: 64];
            2'd0: data_out = mem_dataOut[127: 96];
        endcase
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
        end
        else begin
        end
    end
endmodule
