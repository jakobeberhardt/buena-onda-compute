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
  output cpu_result_type cpu_res,  // cache result (cache->CPU)

  //======== SB Drain Request ======== 
  input  logic          sb_drain_valid,  // 1 => SB wants to write to cache
  input  logic [31:0]   sb_drain_addr,
  input  logic [31:0]   sb_drain_data,
  output logic          sb_drain_done,   // 1 => drain write completed this cycle

  //foce drain
  input logic force_drain

);


  // Cache states
  typedef enum {
    idle,
    compare_tag,
    allocate,
    write_back,
    drain_store  // for draining from SB
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


  // We'll also handle the address/data that "wins" arbitration
  logic        use_cpu_req;   // 1 => we are servicing the CPU, 0 => SB drain
  logic [31:0] active_addr;
  logic [31:0] active_wdata;  // the data to be (potentially) written


  logic [31:0] write_back_addr;  // Register to hold the address during write-back


  //------------------------------------------------------------------------
  // 0) ARBITRATION: decide who the FSM is servicing this cycle
  //------------------------------------------------------------------------
  // Priority example: CPU > SB.except if store buffer is full
  // If CPU is valid, we ignore SB drain for this cycle (unless we go idle after).
  always_comb begin
    if (cpu_req.valid && !force_drain) begin
      use_cpu_req  = 1'b1;
      active_addr  = cpu_req.addr;
      active_wdata = cpu_req.data;
    end
    else if (sb_drain_valid) begin
      use_cpu_req  = 1'b0;
      active_addr  = sb_drain_addr;
      active_wdata = sb_drain_data;
    end
    else begin
      use_cpu_req  = 1'b0;
      active_addr  = 32'b0;
      active_wdata = 32'b0;
    end
  end



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
    tag_req.index = active_addr[5:4];

    // By default, read from cache data
    data_req.we = '0;
    // Direct-mapped index for cache data
    data_req.index = active_addr[5:4];



    // Prepare the data_write by copying data_read
    data_write = data_read;
    case (active_addr[3:2])
      2'b00: data_write[31:0]   = active_wdata;
      2'b01: data_write[63:32]  = active_wdata;
      2'b10: data_write[95:64]  = active_wdata;
      2'b11: data_write[127:96] = active_wdata;
    endcase

    // Read out the correct word (32-bit) from the cache line (to CPU)
    // For CPU loads, we read out data
    // (We'll do finalValue forwarding in MEM stage if SB needed.)
    case (cpu_req.addr[3:2])
      2'b00: v_cpu_res.data = data_read[31:0];
      2'b01: v_cpu_res.data = data_read[63:32];
      2'b10: v_cpu_res.data = data_read[95:64];
      2'b11: v_cpu_res.data = data_read[127:96];
    endcase

    // Default memory request address (taken from CPU request)
    v_mem_req.addr  = active_addr;
    // Default memory request data (used in write)
    v_mem_req.data  = data_read;
    // Default memory request is read
    v_mem_req.rw    = '0;
    // Default memory request not valid
    v_mem_req.valid = '0;

    // Default SB drain done
    sb_drain_done = 1'b0;

    if (rstate == write_back) begin
      v_mem_req.addr = write_back_addr;
    end
    else begin
      v_mem_req.addr  = active_addr;
    end

    // ------------------------------------ Cache FSM ----------------------------------
    case (rstate)

      //--------------------------------------------------------------------------
      // idle state
      //--------------------------------------------------------------------------
      idle: begin
        // If there is a CPU request, then compare cache tag
        // If either CPU or SB presents a request
        if (use_cpu_req) begin
          // CPU request
          vstate = compare_tag;
        end
        else if (sb_drain_valid) begin
            //$display("Will Drain store: addr=%0h, data=%0h", sb_drain_addr, sb_drain_data);
            // Mark line dirty
          tag_req.we     = 1'b1;
          tag_write.tag   = sb_drain_addr[TAGMSB:TAGLSB];    // keep old tag
          tag_write.valid = 1'b1;
          tag_write.dirty = 1'b1;

          // Write data
          data_req.we    = 1'b1;
          //data_write     = data_read;  // then we override correct word as needed above

          // Indicate to SB that this drain is done
          sb_drain_done = 1'b1;

          // Next cycle, return to idle
          vstate = idle;

          //$display("Drain store: addr=%0h, data=%0h, data_write=%0h", sb_drain_addr, sb_drain_data, data_write);
            // Start draining from SB
            vstate = idle;
          end
        else begin
          // no requests, stay idle
          vstate = idle;
        end
      end

      //--------------------------------------------------------------------------
      // compare_tag state
      //--------------------------------------------------------------------------
      compare_tag: begin
        //$display("Comparing tag: addr=%0h, data=%0h, tag_read=%0h, mem req valid=%0d", active_addr, active_wdata, tag_read, mem_req.valid);
        // cache hit (tag match and cache entry is valid)
        if ((cpu_req.addr[TAGMSB:TAGLSB] == tag_read.tag) &&
            (tag_read.valid)) begin
          v_cpu_res.ready = '1; // Pipeline sees done

          // write hit
          if (cpu_req.rw) begin
            // read/modify cache line
            // WIth store buffer we do not write now, but only when we drain
            tag_req.we    = '1;
            //data_req.we   = '1;
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
            //write_back_addr = { tag_read.tag, active_addr[TAGLSB-1:0] };

            //v_mem_req.addr = write_back_addr; // Use the captured address
            //$display("Time: %0t | Write back in compare : addr=%0h, data=%0h",$time, v_mem_req.addr, data_read);
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
        //$display("Allocate: addr=%0h, data=%0h, mem_data_ready=%0d, mem_req_valid=%0d", v_mem_req.addr, data_read, mem_data.ready, mem_req.valid);
        v_mem_req.valid = '1;
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
       // $display("Time: %0t | Write back: addr=%0h, data=%0h, mem_data_ready=%0d, mem_req_valid=%0d",$time, write_back_addr, data_read, mem_data.ready, mem_req.valid);
        v_mem_req.rw = '1; // Write back
        v_mem_req.addr = write_back_addr; // Ensure we're using the correct address

        // write back is completed
        if (mem_data.ready) begin
          // issue new memory request (allocating a new line)
          v_mem_req.valid = '1;
          v_mem_req.rw    = '0; // Read
          vstate          = allocate;
        end
      end

      //-------------------------------------------------------------------------
      // drain_store (SB flow)
      //-------------------------------------------------------------------------
      drain_store: begin
        /*// We read the tag for sb_drain_addr, compare, then do a 1-cycle store to data array.
        
        // Mark line dirty
        tag_req.we     = 1'b1;
        tag_write.tag   = sb_drain_addr[TAGMSB:TAGLSB];     // keep old tag
        tag_write.valid = 1'b1;
        tag_write.dirty = 1'b1;

        // Write data
        data_req.we    = 1'b1;
        data_write     = data_read;  // then we override correct word as needed above

        // Indicate to SB that this drain is done
        sb_drain_done = 1'b1;*/

        // Next cycle, return to idle
        vstate = idle;

        //$display("Drain store: addr=%0h, data=%0h", sb_drain_addr, sb_drain_data);
      end

    endcase
  end

  //--------------------------------------------------------------------------
  // Synchronous state update
  //--------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (reset) begin
      rstate <= idle;
        write_back_addr <= 32'b0; // **Reset the write_back_addr**

    end
    else begin
      rstate <= vstate;
      if ((rstate == compare_tag) && (vstate == write_back)) begin
        write_back_addr <= { tag_read.tag, active_addr[TAGLSB-1:0] };
      end
    end
  end

  //print cache state
  always_ff @(posedge clock) begin
    if (rstate == write_back) begin
      //$display("Write back: addr=%0h, data=%0h", mem_req.addr, data_read);
    end
    if (`DEBUG) begin
      $display("---Cache State---");
      $display("Cache State: %0d", rstate);
      $display("SB Drain Valid: %0d", sb_drain_valid);
      $display("SB Drain Addr: %0h", sb_drain_addr);
      $display("SB Drain Data: %0h", sb_drain_data);
      $display("CPU Req Valid: %0d", cpu_req.valid);
      $display("CPU Force Drain: %0d", force_drain);
      $display("CPU Req Addr: %0h", cpu_req.addr);
      $display("Mem req %p", mem_req);
      $display("Mem data %p", mem_data);
      $display("---Cache State---");
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
