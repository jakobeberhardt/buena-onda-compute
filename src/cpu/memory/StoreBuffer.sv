`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable

`include "../../interfaces/PipelineInterface.svh"


module StoreBuffer #(
  parameter ENTRY_COUNT = 4
)(
  input  logic                clock,
  input  logic                reset,

  // Enqueue interface
  input  logic                enq_valid,      // Request to enqueue
  input  logic [31:0]         enq_addr,
  input  logic [31:0]         enq_data,
  output logic                enq_ready,      // 1 if we can accept
  input  logic [3:0]          enq_wstrb, 

  // Dequeue/drain interface
  input  logic                deq_req,        // Request to drain 1 entry
  output logic [31:0]         deq_addr,
  output logic [31:0]         deq_data,
  output logic                deq_valid,      // 1 if there's an entry to drain

  // For load forwarding
  input  logic [31:0]         load_addr,
  output logic [31:0]         sb_load_data,
  output logic                sb_load_hit,
  output logic [$clog2(ENTRY_COUNT+1)-1:0] count_out,
  output logic full,

  // For flushing (optional, e.g., drain or debug)
  input  logic                flush,
  input logic [2:0]              excpt_in
);

  

  sb_entry_t store_buf[ENTRY_COUNT];

  // Head/tail for FIFO usage (or you could do a circular buffer)
  int unsigned head, tail;
  logic [$clog2(ENTRY_COUNT+1)-1:0] count; 



  //--------------------------------------------------------------------------
  // Enqueue logic
  //--------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset | excpt_in) begin
      head  <= '0;
      tail  <= '0;
      count <= '0;
      for (int i=0; i<ENTRY_COUNT; i++) begin
        store_buf[i].valid <= 1'b0;
      end
    end else begin
      // Flush logic (optional: clear the buffer)
      if (flush) begin
        head  <= '0;
        tail  <= '0;
        count <= '0;
        for (int i=0; i<ENTRY_COUNT; i++) begin
          store_buf[i].valid <= 1'b0;
        end
      end
      else begin
        // Enqueue
        if (enq_valid && enq_ready) begin
          store_buf[tail].valid <= 1'b1;
          store_buf[tail].addr  <= enq_addr;
          store_buf[tail].data  <= enq_data;
          store_buf[tail].wstrb <= enq_wstrb;
          tail  <= (tail + 1) % ENTRY_COUNT;
          count <= count + 1;
        end

        // Dequeue
        if (deq_req && deq_valid) begin
          store_buf[head].valid <= 1'b0;
          head  <= (head + 1) % ENTRY_COUNT;
          count <= count - 1;
        end
      end
    end
  end

  function logic [31:0] apply_wstrb(
    input logic [31:0] old_data,
    input logic [31:0] new_data,
    input logic [3:0]  wstrb
  );
    logic [31:0] out;
    out = old_data;
    if (wstrb[3]) out[ 7: 0] = new_data[ 7: 0];
    if (wstrb[2]) out[15: 8] = new_data[15: 8];
    if (wstrb[1]) out[23:16] = new_data[23:16];
    if (wstrb[0]) out[31:24] = new_data[31:24];
    //$display("In apply_wstrb = %0p", out);
    return out;
  endfunction


  // enq_ready = 1 if there's space in buffer
  assign enq_ready = (count < ENTRY_COUNT);

  // deq_valid = 1 if there's at least one entry to drain
  assign deq_valid = (count > 0);

  // The entry we would drain
  assign deq_addr = store_buf[head].addr;
  assign deq_data = store_buf[head].data;

  logic        match_found;
  logic [31:0] match_data;
  logic [31:0] newest_idx;
  logic [31:0] base_data;   
  logic [31:0] merged_data;

  always_comb begin
    match_found = 1'b0;
    base_data   = '0;
    sb_load_hit  = 1'b0;
    

    // First, default to “no match”:
    sb_load_data = base_data;
    merged_data = base_data;
    for (int i = ENTRY_COUNT-1; i >= 0; i--) begin
      if (store_buf[i].valid && (store_buf[i].addr == load_addr)) begin
        sb_load_hit  = 1'b1;
        merged_data  = apply_wstrb(merged_data, store_buf[i].data, store_buf[i].wstrb);

      end
    end

    sb_load_data = merged_data;
    $display("In sb_load_data = %0p", sb_load_data);
  end

  //assign sb_load_hit  = match_found;
  assign count_out    = count;
  assign full         = (count == ENTRY_COUNT);

  if (`DEBUG) begin
    always @(posedge clock) begin
      //print store buffer details
        $display("==== Final Store Buffer ====");
        $display("Head: %0b, Tail: %0b, Count: %0b, full: %0b, entry_count: %0b", head, tail, count, full, ENTRY_COUNT);
        for (int i = 0; i < ENTRY_COUNT; i = i + 1) begin
            $display("StoreBuffer[%0d] = %0p", i, store_buf[i]);
        end
        $display("==== Final Store Buffer ====");


    end
  end	

endmodule
