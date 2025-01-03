`define DEBUG 1  // Set to 1 to enable debug prints, 0 to disable
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

    //stall pipeline if cache is in a miss or memory is not ready
    output logic                stall
);

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
    // 3) Instantiate the cache FSM
    //========================================================
    cpu_result_type cpu_res;

    dm_cache_fsm cache_controller(
        .clock       (clock),
        .reset       (reset),
        .cpu_req   (cpu_req),
        .cpu_res   (cpu_res),
        .mem_req   (mem_req),
        .mem_data  (mem_data)
    );

    //========================================================
    // 4) Instantiate the memory
    //========================================================
    DMemory main_memory (
        .clock    (clock),
        .reset    (reset),
        .mem_req  (mem_req),   // from the cache
        .mem_data (mem_data)   // goes back to cache
    );

    //========================================================
    // 5) Instantiate the Store Buffer
    //========================================================
    logic        sb_push_valid;
    logic [31:0] sb_push_addr;
    logic [31:0] sb_push_data;
    logic        sb_push_ready;

    logic        sb_drain_valid;
    logic [31:0] sb_drain_addr;
    logic [31:0] sb_drain_data;
    logic        sb_drain_ready;

    logic [31:0] bypass_data;
    logic        bypass_hit;

    StoreBuffer #(.ENTRY_COUNT(4)) store_buffer_inst (
        .clock         (clock),
        .reset         (reset),

        // Push interface
        .sb_push_valid (sb_push_valid),
        .sb_push_addr  (sb_push_addr),
        .sb_push_data  (sb_push_data),
        .sb_push_ready (sb_push_ready),

        // Drain interface
        .sb_drain_valid(sb_drain_valid),
        .sb_drain_addr (sb_drain_addr),
        .sb_drain_data (sb_drain_data),
        .sb_drain_ready(sb_drain_ready),

        // Load bypass
        .load_addr     (ex_mem_bus_in.alu_result),
        .bypass_data   (bypass_data),
        .bypass_hit    (bypass_hit)
    );

    //========================================================
    // 6) Control Logic for the Store Buffer
    //========================================================
    // Determine if the current instruction is a store
    logic isStore;
    assign isStore = (ex_mem_bus_in.opcode == SW);

    // Determine if the current instruction is a load
    logic isLoad;
    assign isLoad = (ex_mem_bus_in.opcode == LW);

    // Logic to push store to Store Buffer on store hit
    // Assuming cache_controller provides a 'hit' signal; 
    logic cache_hit;
    assign cache_hit = cpu_res.ready && (cpu_req.valid && ~isLoad); // Simplistic assumption

    // Push to Store Buffer if it's a store and cache hit
    assign sb_push_valid = isStore && cache_hit;
    assign sb_push_addr  = cpu_req.addr;
    assign sb_push_data  = cpu_req.data;


     // Drain logic: when ALU operation is in C stage (not a load/store), drain SB
    logic isAluOp;
    assign isAluOp = (ex_mem_bus_in.opcode == ALUopR || ex_mem_bus_in.opcode == ALUopI) && cpu_req.valid; 

    // Connect drain_ready signal based on whether we're in an ALU op cycle
    assign sb_drain_ready = isAluOp;

    //========================================================
    // 7) Handle Load Bypass and Final WB Value
    // Drive MEM->WB bus from the cache result
    //========================================================
    logic [31:0] finalValue;
    always_comb begin
        finalValue = '0;
        unique case (ex_mem_bus_in.opcode)
          ALUopR, ALUopI: finalValue = ex_mem_bus_in.alu_result; 
          LW: begin
              if (bypass_hit) begin
                  finalValue = bypass_data; // Load bypasses SB
              end
              else begin
                  finalValue = cpu_res.data; // Load from cache
              end
          end
          SW:             finalValue = 32'b0;        // store doesn't produce WB
          default:        finalValue = ex_mem_bus_in.alu_result;
        endcase
    end

    //Flush the cache, (For testing purposes)
   always_ff @(posedge clock) begin 
        if (ex_mem_bus_in.opcode == DRAIN_CACHE) begin
            main_memory.memArray[0] <= cache_controller.cdata.data_mem[0];
            main_memory.memArray[1] <= cache_controller.cdata.data_mem[1];
            main_memory.memArray[2] <= cache_controller.cdata.data_mem[2];
            main_memory.memArray[3] <= cache_controller.cdata.data_mem[3];
        end
    end
    

    // The pipeline bus to WB
    assign mem_wb_bus_out.instruction = ex_mem_bus_in.instruction;
    assign mem_wb_bus_out.opcode      = ex_mem_bus_in.opcode;
    assign mem_wb_bus_out.rd          = ex_mem_bus_in.rd;
    assign mem_wb_bus_out.wb_value    = finalValue;

    //========================================================
    // 9) Stall Logic
    //========================================================
    // Stall if:
    // - Cache is handling a miss (cpu_res.ready == 0)
    // - Store Buffer is full (cannot push a new store)
    // - Currently draining SB entry and cache is busy
    assign stall = (
        (~cpu_res.ready && cpu_req.valid)
        // Cache miss handling
        // || (isStore && ~sb_push_ready)         // SB is full on store
    );

    // print all signals
    always_ff @(posedge clock) begin
        if (`DEBUG) begin
            $display("MEM----------------------------");
            $display("Time: %0t | DEBUG: Ex_mem_bus_in = %p", $time, ex_mem_bus_in);
            $display("Time: %0t | DEBUG: CPU_REQ = %p", $time, cpu_req);
            $display("Time: %0t | DEBUG: MEM_REQ = %p", $time, mem_req);
            $display("Time: %0t | DEBUG: MEM_DATA = %p", $time, mem_data);
            $display("Time: %0t | DEBUG: CPU_RES = %p", $time, cpu_res);
            $display("Time: %0t | DEBUG: MEMWBValue = %0d", $time, finalValue);
            $display("MEM----------------------------");
        end
    end

endmodule
