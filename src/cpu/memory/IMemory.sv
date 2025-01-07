module IMemory(
    input  logic [31:0] addr,
    output logic [31:0] dataOut
);
    logic [31:0] IMem[0:1023];
    assign dataOut = IMem[addr];
endmodule

/*
module IMemory(
    input  logic        clock,
    input  logic        reset,
    input  logic [31:0] addr,
    output logic [31:0] dataOut,
    output logic        mem_valid
);

    logic [31:0] IMem[0:1023];
    logic [2:0] latency_count;

    assign dataOut   = (latency_count == 0) ? IMem[addr] : 32'hDEADBEEF;
    assign mem_valid = (latency_count == 0);

    logic [31:0] last_addr;

    always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        last_addr      <= 'hFFFF_FFFF;
        latency_count  <= 5;
    end
    else begin
        if (addr != last_addr) begin
        last_addr     <= addr;
        latency_count <= 5;
        end
        else if (latency_count > 0) begin
        latency_count <= latency_count - 1;
        end
    end
    end


endmodule

*/