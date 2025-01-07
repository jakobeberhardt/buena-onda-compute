`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"

//======================================================================
// Cache data memory, single port, 1024 blocks
//======================================================================
module dm_cache_data (
  input  bit              clock,
  input  bit              reset,       // Added reset signal
  input  cache_req_type   data_req,    // data request/command
  input  cache_data_type  data_write,  // write port (128-bit line)
  output cache_data_type  data_read    // read port
);

  // Cache data memory array
  cache_data_type data_mem[0:4];

  // Combinational read
  assign data_read = data_mem[data_req.index];

  // Synchronous write with reset
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < 4; i++) begin
        data_mem[i] <= '0;
      end
    end else if (data_req.we) begin
      data_mem[data_req.index] <= data_write;
      //$display("Writing to data_mem[%0d] = %0p", data_req.index, data_write);
    end
  end

endmodule


//======================================================================
// Cache tag memory, single port, 1024 blocks
//======================================================================
module dm_cache_tag (
  input  bit                 clock,      // write clock
  input  bit                 reset,      // Added reset signal
  input  cache_req_type      tag_req,    // tag request/command
  input  cache_tag_type      tag_write,  // write port
  output cache_tag_type      tag_read    // read port
);

  // Cache tag memory array
  cache_tag_type tag_mem [0:4];

  // Combinational read
  assign tag_read = tag_mem[tag_req.index];

  // Synchronous write with reset
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < 4; i++) begin
        tag_mem[i] <= '0;
      end
    end else if (tag_req.we) begin
      tag_mem[tag_req.index] <= tag_write;
    end
  end

endmodule

