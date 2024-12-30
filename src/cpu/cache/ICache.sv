module ICache(
    input  logic         clock,
    input  logic         reset,
    
    // to fetch stage
    input  logic [31:0]  addr_in,     
    output logic [31:0]  data_out,    
    output logic         data_out_valid,

    // to IMemory
    output logic [31:0]  mem_addr,
    input  logic [31:0]  mem_dataOut,
    input  logic         mem_valid
);
    assign mem_addr = addr_in;
    assign data_out_valid = mem_valid;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            data_out <= 32'h0;
        end
        else begin
            if (mem_valid) begin
                data_out <= mem_dataOut;
            end
        end
    end

endmodule
