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
          tail  <= (tail + 1) % ENTRY_COUNT;
          count <= count + 1;
        end

        // Dequeue
        if (deq_req && deq_valid) begin
            //$display("Dequeueing entry %0d", head);
          // We assume we "pop" after reading out entry
          store_buf[head].valid <= 1'b0;
          head  <= (head + 1) % ENTRY_COUNT;
          count <= count - 1;
        end
      end
    end
  end

  // enq_ready = 1 if there's space in buffer
  assign enq_ready = (count < ENTRY_COUNT);

  // deq_valid = 1 if there's at least one entry to drain
  assign deq_valid = (count > 0);

  // The entry we would drain
  assign deq_addr = store_buf[head].addr;
  assign deq_data = store_buf[head].data;

  //--------------------------------------------------------------------------
  // Load forwarding: check if load_addr matches any entry
  // For simplicity, we’ll just check all valid entries and pick the newest.
  //--------------------------------------------------------------------------
  logic        match_found;
  logic [31:0] match_data;
  logic [31:0] newest_idx;

  always_comb begin
    match_found = 1'b0;
    match_data  = '0;
    // In a real design, you'd pick the *newest* matching store in program order.
    // Here, we do a simple search from tail backwards or head to tail.
    for (int i = 0; i < ENTRY_COUNT; i++) begin
        //$display("Checking entry %0d, with addr %0d and data %0d,valid = %0d, load addr: %0d",i, store_buf[i].addr, store_buf[i].data, store_buf[i].valid,load_addr );
      if (store_buf[i].valid && (store_buf[i].addr == load_addr)) begin
        match_found = 1'b1;
        match_data  = store_buf[i].data;
        // break on the most recent if you track an age field (not shown).
      end
    end
  end

  assign sb_load_hit  = match_found;
  assign sb_load_data = match_data;
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
