// StoreBuffer.sv
module StoreBuffer #(
    parameter int ENTRY_COUNT = 4
)(
    input  logic        clock,
    input  logic        reset,

    // Push interface (from MEM stage for store hits)
    input  logic        sb_push_valid,  // 1 = new store request
    input  logic [31:0] sb_push_addr,   // store address
    input  logic [31:0] sb_push_data,   // store data
    output logic        sb_push_ready,  // 1 = buffer has space

    // Drain interface (to write into cache data array)
    output logic        sb_drain_valid, // 1 = has data to drain
    output logic [31:0] sb_drain_addr,  // address to write
    output logic [31:0] sb_drain_data,  // data to write
    input  logic        sb_drain_ready, // 1 = can accept drain

    // Load bypass
    input  logic [31:0] load_addr,
    output logic [31:0] bypass_data,
    output logic        bypass_hit
);

    typedef struct packed {
        logic valid;
        logic [31:0] addr;
        logic [31:0] data;
    } sb_entry_t;

    sb_entry_t buffer [ENTRY_COUNT];
    int head, tail, count;

    // Push logic: accept new store if buffer is not full
    assign sb_push_ready = (count < ENTRY_COUNT);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < ENTRY_COUNT; i++) begin
                buffer[i].valid <= 1'b0;
                buffer[i].addr  <= 32'h0;
                buffer[i].data  <= 32'h0;
            end
            head <= 0;
            tail <= 0;
            count <= 0;
        end
        else begin
            // Push new store into buffer
            if (sb_push_valid && sb_push_ready) begin
                buffer[tail].valid <= 1'b1;
                buffer[tail].addr  <= sb_push_addr;
                buffer[tail].data  <= sb_push_data;
                tail <= (tail + 1) % ENTRY_COUNT;
                count <= count + 1;
            end

            // Drain store from buffer into cache
            if (sb_drain_valid && sb_drain_ready && count > 0) begin
                buffer[head].valid <= 1'b0;
                head <= (head + 1) % ENTRY_COUNT;
                count <= count - 1;
            end
        end
    end

    // Bypass logic: check if any store in buffer matches load address
    logic [31:0] bypass_data_temp;
    logic bypass_hit_temp;

    always_comb begin
        bypass_data_temp = 32'h0;
        bypass_hit_temp = 1'b0;
        for (int i = 0; i < ENTRY_COUNT; i++) begin
            if (buffer[i].valid && (buffer[i].addr == load_addr)) begin
                bypass_data_temp = buffer[i].data;
                bypass_hit_temp = 1'b1;
            end
        end
    end

    assign bypass_data = bypass_data_temp;
    assign bypass_hit  = bypass_hit_temp;

    // Drain signals: valid if buffer is not empty
    assign sb_drain_valid = (count > 0);
    assign sb_drain_addr  = buffer[head].addr;
    assign sb_drain_data  = buffer[head].data;

endmodule
