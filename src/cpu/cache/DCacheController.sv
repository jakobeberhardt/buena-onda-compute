`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"


//======================================================================
// Cache Finite State Machine
//======================================================================
module dm_cache_fsm (
  input  bit                     clock,
  input  bit                     reset,
  input  cpu_req_type cpu_req,    // CPU request input (CPU->cache)
  input  mem_data_type mem_data,  // memory response (memory->cache)
  output mem_req_type  mem_req,   // memory request (cache->memory)
  output cpu_result_type cpu_res  // cache result (cache->CPU)
);


  // Cache states
  typedef enum {
    idle,
    compare_tag,
    allocate,
    write_back
  } cache_state_type;

  // FSM state register
  cache_state_type rstate, vstate;

  // Interface signals to tag memory
  cache_tag_type tag_read;   // tag read result
  cache_tag_type tag_write;  // tag write data
  cache_req_type tag_req;    // tag request

  // Interface signals to cache data memory
  cache_data_type data_read;   // cache line read data
  cache_data_type data_write;  // cache line write data
  cache_req_type  data_req;    // data request

  // Temporary variable for cache controller result
  cpu_result_type v_cpu_res;

  // Temporary variable for memory controller request
  mem_req_type v_mem_req;

  // Connect to output ports
  assign mem_req = v_mem_req;
  assign cpu_res = v_cpu_res;

  // Combinational FSM
  always_comb begin
    // ------------------------- default values for all signals -------------------------
    // By default, stay in the same state
    vstate = rstate;

    // Default CPU result: zero out everything
    v_cpu_res = '{ data: '0, ready: '0 };

    // Default tag write
    tag_write = '{ valid: '0, dirty: '0, tag: '0 };

    // By default, read from the tag memory
    tag_req.we = '0;
    // Direct-mapped index for tag
    tag_req.index = cpu_req.addr[5:4];

    // By default, read from cache data
    data_req.we = '0;
    // Direct-mapped index for cache data
    data_req.index = cpu_req.addr[5:4];

    // Prepare the data_write by copying data_read
    data_write = data_read;
    case (cpu_req.addr[3:2])
      2'b00: data_write[31:0]   = cpu_req.data;
      2'b01: data_write[63:32]  = cpu_req.data;
      2'b10: data_write[95:64]  = cpu_req.data;
      2'b11: data_write[127:96] = cpu_req.data;
    endcase

    // Read out the correct word (32-bit) from the cache line (to CPU)
    case (cpu_req.addr[3:2])
      2'b00: v_cpu_res.data = data_read[31:0];
      2'b01: v_cpu_res.data = data_read[63:32];
      2'b10: v_cpu_res.data = data_read[95:64];
      2'b11: v_cpu_res.data = data_read[127:96];
    endcase

    // Default memory request address (taken from CPU request)
    v_mem_req.addr  = cpu_req.addr;
    // Default memory request data (used in write)
    v_mem_req.data  = data_read;
    // Default memory request is read
    v_mem_req.rw    = '0;
    // Default memory request not valid
    v_mem_req.valid = '0;

    // ------------------------------------ Cache FSM ----------------------------------
    case (rstate)

      //--------------------------------------------------------------------------
      // idle state
      //--------------------------------------------------------------------------
      idle: begin
        // If there is a CPU request, then compare cache tag
        if (cpu_req.valid) begin
          vstate = compare_tag;
        end
      end

      //--------------------------------------------------------------------------
      // compare_tag state
      //--------------------------------------------------------------------------
      compare_tag: begin
        // cache hit (tag match and cache entry is valid)
        if ((cpu_req.addr[TAGMSB:TAGLSB] == tag_read.tag) &&
            (tag_read.valid)) begin
          v_cpu_res.ready = '1;

          // write hit
          if (cpu_req.rw) begin
            // read/modify cache line
            tag_req.we    = '1;
            data_req.we   = '1;
            // no change in tag
            tag_write.tag   = tag_read.tag;
            tag_write.valid = '1;
            // cache line is now dirty
            tag_write.dirty = '1;
          end
          // transaction is finished
          vstate = idle;
        end else begin
          // cache miss
          tag_req.we       = '1;
          tag_write.valid  = '1;
          tag_write.tag    = cpu_req.addr[TAGMSB:TAGLSB];
          // cache line is dirty if write
          tag_write.dirty  = cpu_req.rw;

          // generate memory request on miss
          v_mem_req.valid = '1;

          // compulsory miss or miss with clean block
          if ((tag_read.valid == 1'b0) || (tag_read.dirty == 1'b0)) begin
            // wait until a new block is allocated
            vstate = allocate;
          end else begin
            // miss with a dirty line
            // write back address
            v_mem_req.addr = { tag_read.tag, cpu_req.addr[TAGLSB-1:0] };
            v_mem_req.rw   = '1; // Write back
            // wait until write is completed
            vstate = write_back;
          end
        end
      end

      //--------------------------------------------------------------------------
      // allocate state (waiting for a new cache line from memory)
      //--------------------------------------------------------------------------
      allocate: begin
        // memory controller has responded
        if (mem_data.ready) begin
          // re-compare tag for write miss (need to modify correct word)
          vstate = compare_tag;

          // update cache line data
          data_write = mem_data.data;
          data_req.we = '1;
        end
      end

      //--------------------------------------------------------------------------
      // write_back state (writing back dirty line to memory)
      //--------------------------------------------------------------------------
      write_back: begin
        // write back is completed
        if (mem_data.ready) begin
          // issue new memory request (allocating a new line)
          v_mem_req.valid = '1;
          v_mem_req.rw    = '0; // Read
          vstate          = allocate;
        end
      end

    endcase
  end

  //--------------------------------------------------------------------------
  // Synchronous state update
  //--------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (reset) begin
      rstate <= idle;
    end
    else begin
      rstate <= vstate;
    end
  end

  //--------------------------------------------------------------------------
  // Instantiate cache tag/data memory
  //--------------------------------------------------------------------------
  dm_cache_tag ctag (
    .clock      (clock),
    .reset      (reset),
    .tag_req  (tag_req),
    .tag_write(tag_write),
    .tag_read (tag_read)
  );

  dm_cache_data cdata (
    .clock        (clock),
    .reset        (reset),
    .data_req   (data_req),
    .data_write (data_write),
    .data_read  (data_read)
  );

endmodule
