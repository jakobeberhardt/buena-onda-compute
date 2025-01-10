module ICache(
    input  logic        clock,
    input  logic        reset,
    input  logic [31:0] addr_in, 
    output logic [31:0] data_out, 

    output logic [31:0] mem_addr,
    input  logic [31:0] mem_dataOut
);


    assign mem_addr  = addr_in;  
    assign data_out  = mem_dataOut;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
        end
        else begin
        end
    end

endmodule