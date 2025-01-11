module ICache(
    input  logic        clock,
    input  logic        reset,
    input  logic [31:0] addr_in, 
    output logic [31:0] data_out, 
    output logic        iCache_stall, 
    output logic [31:0] mem_addr,
    input  logic [31:0] mem_dataOut
);

    assign mem_addr  = addr_in;
    assign data_out  = mem_dataOut;
    localparam int DELAY_CYCLES = 5;
    logic [31:0] prev_addr;

    logic [$clog2(DELAY_CYCLES+1)-1:0] stall_counter;
    logic stall_reg;
    assign iCache_stall = stall_reg;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            prev_addr      <= '0;
            stall_counter  <= '0;
            stall_reg      <= 1'b0;
        end
        else begin
            if (addr_in != prev_addr) begin
                stall_reg      <= 1'b1;
                stall_counter  <= DELAY_CYCLES;
                prev_addr      <= addr_in;
            end
            else begin
                if (stall_counter > 0) begin
                    stall_counter <= stall_counter - 1'b1;
                end
                if (stall_counter == 1) begin
                    stall_reg <= 1'b0;
                end
            end
        end
    end

endmodule
