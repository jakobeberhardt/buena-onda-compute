`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`include "../../interfaces/PipelineInterface.svh"
`include "../core/utils/Opcodes.sv"
`include "../../interfaces/ControlSignals.svh"


module MEM(
    input  logic                 clock,
    input  logic                 reset,

    // The EX->MEM pipeline bus
    input wire  ex_mem_bus_t          ex_mem_bus_in,

    // The MEM->WB pipeline bus
    output wire mem_wb_bus_t          mem_wb_bus_out,

    //stall pipeline if cache is busy or sb is full
    output logic                stall,
    input logic [2:0]               excpt_in
);

    localparam ENTRY_COUNT = 4;

    //========================================================
    // 1) Translate ex_mem_bus_in -> Cache FSM CPU request
    //========================================================
    //build cpu_req_type from ex_mem.
    cpu_req_type  cpu_req;
    assign cpu_req.addr  = ex_mem_bus_in.alu_result;  // 32-bit address
    assign cpu_req.data  = ex_mem_bus_in.b_val;       // data to store
    assign cpu_req.rw    = (ex_mem_bus_in.opcode == SW); // 1=write,0=read
    assign cpu_req.valid = (
        (ex_mem_bus_in.opcode == LW) ||
        (ex_mem_bus_in.opcode == SW) 
    );

    //========================================================
    // 2) Wires for the cache <-> memory
    //========================================================
    mem_req_type   mem_req;
    mem_data_type  mem_data;

    

    //========================================================
    // 3) Instantiate the Store Buffer
    //========================================================
    // For a 32-bit system, address[1:0] chooses the byte offset:
    logic [3:0] wstrb;
    always_comb begin
        wstrb = 4'b0000;
        if (ex_mem_bus_in.opcode == SW ) begin
            wstrb = 4'b1111;
            if (ex_mem_bus_in.funct3 == SB_FUNCT3) begin
                case (ex_mem_bus_in.alu_result[1:0])
                    2'b00: wstrb = 4'b0001;
                    2'b01: wstrb = 4'b0010;
                    2'b10: wstrb = 4'b0100;
                    2'b11: wstrb = 4'b1000;
                endcase
            end
        end
    end

    logic             sb_enq_valid;
    logic [31:0]      sb_enq_addr, sb_enq_data;
    logic             sb_enq_ready;

    logic             sb_deq_req;
    logic             sb_deq_valid;
    logic [31:0]      sb_deq_addr, sb_deq_data;
    logic             sb_drain_done; // from the cache FSM

    // For load forwarding
    logic [31:0] sb_load_data;
    logic        sb_load_hit;

    logic [2:0] sb_count;
    logic force_sb_drain;  // force drain if SB is full

    
    StoreBuffer #(.ENTRY_COUNT(4)) sb (
        .clock       (clock),
        .reset       (reset),

        // Enqueue signals
        .enq_valid   (sb_enq_valid),
        .enq_addr    (sb_enq_addr),
        .enq_data    (sb_enq_data),
        .enq_ready   (sb_enq_ready),
        .enq_wstrb   (wstrb),

        // Dequeue signals
        .deq_req     (sb_deq_req),
        .deq_addr    (sb_deq_addr),
        .deq_data    (sb_deq_data),
        .deq_valid   (sb_deq_valid),

        // Load forwarding
        .load_addr   (cpu_req.addr),
        .sb_load_data(sb_load_data),
        .sb_load_hit (sb_load_hit),

        // Count of entries
        .count_out(sb_count),
        .full       (force_sb_drain),  // force drain if SB is full

        // Flush for (debug or test)
        .flush       (1'b0),  
        .excpt_in    (excpt_in)
    );

    //========================================================
    // 4) Instantiate the cache FSM
    //========================================================
    cpu_result_type cpu_res;

    dm_cache_fsm cache_controller(
        .clock       (clock),
        .reset       (reset),
        .cpu_req   (cpu_req),
        .cpu_res   (cpu_res),
        .mem_req   (mem_req),
        .mem_data  (mem_data),
        // SB drain interface
        .sb_drain_valid(sb_deq_valid),   // 1 => SB has an entry to drain
        .sb_drain_addr (sb_deq_addr),
        .sb_drain_data (sb_deq_data),
        .sb_drain_done (sb_drain_done),  // FSM signals done
        .force_drain   (force_sb_drain),  // force drain if SB is full
        .excpt_in      (excpt_in)
    );

    //========================================================
    // 5) Instantiate the memory
    //========================================================
    DMemory main_memory (
        .clock    (clock),
        .reset    (reset),
        .mem_req  (mem_req),   // from the cache
        .mem_data (mem_data),   // goes back to cache
        .excpt_in (excpt_in)
    );


    //========================================================
    // 6) Decide When to Dequeue (Drain) from SB
    //========================================================
    assign force_sb_drain = sb.full;


    // If we want to force a drain, we set deq_req = 1 even if cpu_req.valid is 1
    assign sb_deq_req = sb_deq_valid && ( ~cpu_req.valid || force_sb_drain );

    // If we are forcing a drain, we stall the pipeline
    //if store buffer is full, we can't enqueue a new store
    //========================================================
    // 7) Enqueue Logic for CPU Store-Hit
    //========================================================
    // We detect a store-hit by:
    //   1) cpu_req.rw == 1 => store
    //   2) cpu_req.valid == 1
    //   3) cpu_res.ready == 1 => The cache says "store is done" from pipeline viewpoint (HIT)

    logic store_hit_and_done;
    assign store_hit_and_done = (cpu_req.valid && cpu_req.rw && cpu_res.ready);

    assign sb_enq_valid = store_hit_and_done;
    assign sb_enq_addr  = cpu_req.addr;
    assign sb_enq_data  = cpu_req.data;


    //========================================================
    // 8) Load Bypass (Forwarding) & Final WB Value
    //========================================================
    logic [31:0] finalValue;
    logic [31:0] rawData;

    always_comb begin
        finalValue = '0;

        unique case (ex_mem_bus_in.opcode)
            ALUopR, ALUopI: begin
            finalValue = ex_mem_bus_in.alu_result;
            end

            LW: begin
            // 1) Grab the 32-bit raw data (either from SB forwarding or from cache)
            if (sb_load_hit) begin
                rawData = sb_load_data;  
                //$display("SB Load Hit: %0d", rawData);
            end else begin
                rawData = cpu_res.data; 
                //$display("Cache Load Hit: %0d", rawData); 
            end

            if (ex_mem_bus_in.funct3 == 3'b000) begin
                // = LB (sign-extended byte)
                unique case (ex_mem_bus_in.alu_result[1:0])
                2'b11: finalValue = {{24{rawData[ 7]}}, rawData[ 7:0]};
                2'b10: finalValue = {{24{rawData[15]}}, rawData[15:8]};
                2'b01: finalValue = {{24{rawData[23]}}, rawData[23:16]};
                2'b00: finalValue = {{24{rawData[31]}}, rawData[31:24]};
                endcase
            end
            else begin
                finalValue = rawData;
            end
            end

            SW: begin
            finalValue = 32'b0;
            end

            default: begin
            finalValue = ex_mem_bus_in.alu_result;
            end
        endcase
    end


    //Flush the cache, (For testing purposes)
    int sb_flushed = 0;
    always_ff @(posedge clock) begin
        if (ex_mem_bus_in.opcode == DRAIN_CACHE) begin
            sb_flushed <= 1;
            // Iterate over every SB entry
            for (int i = 0; i < sb.ENTRY_COUNT; i++) begin

                $display("DRAINING");

                if (sb.store_buf[i].valid) begin
                    // 1) Figure out which 128-bit block in memory
                    automatic int unsigned block_index = sb.store_buf[i].addr[31:4];

                    // 2) Read out the existing block data (128 bits)
                    automatic logic [127:0] block_data = main_memory.memArray[block_index];

                    // 3) Determine which 32-bit word within the 128-bit block
                    //    based on addr[3:2]:
                    unique case (sb.store_buf[i].addr[3:2])
                        2'b00: block_data[ 31:  0] = sb.store_buf[i].data;
                        2'b01: block_data[ 63: 32] = sb.store_buf[i].data;
                        2'b10: block_data[ 95: 64] = sb.store_buf[i].data;
                        2'b11: block_data[127: 96] = sb.store_buf[i].data;
                    endcase

                    $display("Writing Data: %h to Address: %h", sb.store_buf[i].data, sb.store_buf[i].addr);

                    // 4) Write the updated 128-bit block back to memory
                    main_memory.memArray[block_index] = block_data;

                    // 5) Invalidate SB entry so we know it’s drained
                    sb.store_buf[i].valid <= 1'b0;
                end
            end
        end
    end

    always @(posedge clock) begin
        if (sb_flushed) begin
            for (int i = 0; i < 4; i++) begin
                // "tag_mem[i]" is the tag info for index i
                automatic cache_tag_type   curTag   = cache_controller.ctag.tag_mem[i];
                automatic cache_data_type  curData  = cache_controller.cdata.data_mem[i];
                automatic logic [127:0] old_data ;
                automatic logic [127:0] new_data ;

                if (curTag.valid && curTag.dirty) begin
                    //---------------------------------------
                    // 2A) Compute the block address from (tag + index)
                    //---------------------------------------
                    // If your index bits are [5:4], i is 2 bits wide
                    // If your tag bits are [31:6], that is curTag.tag
                    // This concatenation is an example:
                    logic [31:0] block_addr;
                    block_addr[31:6] = curTag.tag;          // Tag
                    block_addr[5:4]  = i[1:0];    // Index
                    block_addr[3:0]  = 4'b0;                // Offset

                    $display("Flushing Cache Line %0d: Writing Data %h to Address %h", 
                            i, curData, block_addr);

                    //---------------------------------------
                    // 2B) Overwrite the entire 128-bit block in memory
                    //---------------------------------------
                    // read the old block from memory
                    old_data = main_memory.memArray[block_addr[31:4]];

                    // replace it with the line data
                    new_data = curData;  // entire 128-bit line

                    // write back to main memory
                    main_memory.memArray[block_addr[31:4]] = new_data;

                    //---------------------------------------
                    // 2C) Clear the dirty bit so we don’t keep re-writing
                    //---------------------------------------
                    // Because you are using a single-port tag memory from the FSM,
                    // you typically need to do a write via the 'tag_req' interface.
                    // As a hack/test, you can do direct assignment if it’s a reg:
                    cache_controller.ctag.tag_mem[i].dirty <= 1'b0;
                end
            end
        end
    end

    

    //========================================================
    // 9) Connect MEM->WB pipeline bus
    //========================================================
    // The pipeline bus to WB
    assign mem_wb_bus_out.instruction = ex_mem_bus_in.instruction;
    assign mem_wb_bus_out.opcode      = ex_mem_bus_in.opcode;
    assign mem_wb_bus_out.rd          = ex_mem_bus_in.rd;
    assign mem_wb_bus_out.wb_value    = finalValue;

    //========================================================
    // 10) Stall Logic
    //========================================================
    // We stall if:
    //   - The cache FSM isn't ready but we have a valid CPU request (load/store).
    //   - The SB is full and we want to enqueue a store (store_hit_and_done).
    //   - Possibly other conditions (e.g., store misses, etc.).
    assign stall = (
        (~cpu_res.ready && cpu_req.valid)
        || (store_hit_and_done && ~sb_enq_ready)
        || (force_sb_drain)
    );

    //========================================================
    // 11) Debug Printing
    //========================================================
    always_ff @(posedge clock) begin
      if (`DEBUG) begin
        $display("MEM----------------------------");
        $display("Time: %0t | ex_mem_bus_in     = %p", $time, ex_mem_bus_in);
        $display("Time: %0t | CPU_REQ          = %p", $time, cpu_req);
        $display("Time: %0t | CPU_RES          = %p", $time, cpu_res);
        $display("Time: %0t | (store_hit_done) = %b", $time, store_hit_and_done);
        $display("Time: %0t | finalValue       = %0d", $time, finalValue);

        // SB debug
        $display("Time: %0t | SB EnqValid/Addr/Data/Ready = %b %h %h %b", 
                  $time, sb_enq_valid, sb_enq_addr, sb_enq_data, sb_enq_ready);
        $display("Time: %0t | SB DeqReq/Valid/Addr/Data  = %b %b %h %h", 
                  $time, sb_deq_req, sb_deq_valid, sb_deq_addr, sb_deq_data);
        $display("Time: %0t | sb_load_hit/data          = %b %h", 
                  $time, sb_load_hit, sb_load_data);
        $display("Time: %0t | sb_drain_done             = %b", $time, sb_drain_done);
        $display("Time: %0t | force_sb_drain            = %b", $time, sb.full);
        $display("Time: %0t | SB count/SBentry    = %0b %0b", $time, sb_count, ENTRY_COUNT);

        $display("Time: %0t | STALL                    = %b", $time, stall);
        $display("MEM----------------------------\n");
      end
    end

endmodule
