`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/PipelineInterface.svh"
`include "../../interfaces/ControlSignals.svh"

module DMemory(
    input  logic                     clock,
    input  logic                     reset,

    // Memory request from the cache
    input  mem_req_type   mem_req,

    // Memory response to the cache
    output mem_data_type  mem_data
);

  // Memory array with 1024 entries (10-bit index: [13:4])
  cache_data_type memArray[0:1023];

  // FSM states
  typedef enum logic [1:0] { M_IDLE, M_WAIT } mstate_t;
  mstate_t rstate, vstate;

  // Wait counter for latency (5 cycles)
  logic [2:0] waitCount;

  // Buffer for read data (optional, depending on design)
  logic [127:0] read_buffer;

  // Initialize memory on reset
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      rstate     <= M_IDLE;
      waitCount  <= 0;
      read_buffer <= '0;
      // Initialize memArray to zero (optional)
    end
    else begin
      rstate <= vstate;

      // Start 5-cycle wait on a valid request
      if (rstate == M_IDLE && mem_req.valid) begin
        waitCount <= 5;
      end
      else if (rstate == M_WAIT && waitCount != 0) begin
        waitCount <= waitCount - 1;
      end

      // If write, do the actual store near the end
      if (rstate == M_WAIT && waitCount == 1 && mem_req.rw == 1'b1) begin
        logic [9:0] block_index;
        block_index = mem_req.addr[13:4]; // Corrected indexing

        $display("Time: %0t | Writing to memArray[%0d] = %0h, address = %0d",
                 $time, block_index, mem_req.data, mem_req.addr);
        memArray[block_index] <= mem_req.data;
      end
    end
  end

  // Combinational logic for FSM and memory response
  always_comb begin
    // Default outputs
    mem_data.data  = '0;
    mem_data.ready = 1'b0;
    vstate         = rstate;

    case (rstate)
      M_IDLE: begin
        if (mem_req.valid) begin
          // Move to WAIT state
          vstate = M_WAIT;
        end
      end

      M_WAIT: begin
        // Decrementing waitCount each cycle
        if (waitCount == 0) begin
          // 5-cycle operation is done
          vstate         = M_IDLE;
          mem_data.ready = 1'b1;

          // If read, pass read data
          if (mem_req.rw == 1'b0) begin
            logic [9:0] block_index;
            block_index = mem_req.addr[13:4]; // Corrected indexing
            mem_data.data = memArray[block_index];
          end
        end
      end
    endcase
  end

  // Debug Printing
  always_ff @(posedge clock) begin
    if(`DEBUG) begin
      $display("Mem req=%p", mem_req);
      $display("Mem data=%p", mem_data);
      $display("Mem state=%d", rstate);
    end
  end 

endmodule
