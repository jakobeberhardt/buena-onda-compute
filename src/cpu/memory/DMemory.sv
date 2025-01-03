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

  // FSM that enforces 5-cycle latency
  // Memory array
  cache_data_type memArray[0:1023];

  typedef enum logic [1:0] { M_IDLE, M_WAIT } mstate_t;
  mstate_t rstate, vstate;

  logic [2:0] waitCount;
  logic [127:0] read_buffer;

  // -----------
  // Next-state logic
  // -----------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      rstate     <= M_IDLE;
      waitCount  <= 0;
      read_buffer <= '0;
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
        memArray[mem_req.addr[5:4]] <= mem_req.data;
      end
    end
  end

  always_comb begin
    // Default outputs
    mem_data.data  = '0;
    mem_data.ready = 1'b0;
    vstate         = rstate;

    case (rstate)
      M_IDLE: begin
        if (mem_req.valid) begin
          // Move to WAIT
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
            mem_data.data = memArray[mem_req.addr[5:4]];
          end
        end
      end
    endcase
  end

endmodule
