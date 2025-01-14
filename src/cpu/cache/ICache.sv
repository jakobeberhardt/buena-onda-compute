module ICache(
    input  logic         clock,
    input  logic         reset,
    input  logic [31:0]  addr_in,
    output logic [31:0]  data_out,
    output logic         iCache_stall,
    output logic [31:0]  mem_addr,
    input  logic [127:0] mem_dataOut
);

    typedef enum logic [1:0] {
        RESET_STATE, 
        IDLE,        
        MISS          
    } cache_state_e;

    cache_state_e state, next_state;
    // 2 bits offset, 2 bits index, top 28 bits as tag
    logic [1:0]  index;
    logic [27:0] tag_in; 
    logic [1:0]  offset;
    logic         validMem [3:0];
    logic [27:0]  tagMem   [3:0];
    logic [127:0] dataMem  [3:0];
    logic [2:0] miss_wait_counter;

    assign offset  = addr_in[1:0];   // lower 2 bits => word offset
    assign index   = addr_in[3:2];   // next 2 bits => which of 4 lines
    assign tag_in  = addr_in[31:4];  // upper 28 bits => tag
    assign mem_addr = addr_in & 32'hFFFFFFFC;
    logic hit;
    assign hit = validMem[index] && (tagMem[index] == tag_in);

    always_comb begin
        unique case (state)
            RESET_STATE:  iCache_stall = 1;      // Always stall in reset
            IDLE:         iCache_stall = !hit;   // Stall if not a hit
            MISS:         iCache_stall = 1;      // Stall during miss penalty
            default:      iCache_stall = 1;
        endcase
    end

    always_comb begin
        next_state = state; 
        case (state)
            RESET_STATE: begin
                next_state = IDLE;
            end

            IDLE: begin
                if (!hit) begin
                    next_state = MISS;
                end
            end

            MISS: begin
                // Wait 5 cycles
                if (miss_wait_counter == 0)
                    next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            validMem[0] <= 0;
            validMem[1] <= 0;
            validMem[2] <= 0;
            validMem[3] <= 0;

            tagMem[0] <= '0;
            tagMem[1] <= '0;
            tagMem[2] <= '0;
            tagMem[3] <= '0;

            dataMem[0] <= '0;
            dataMem[1] <= '0;
            dataMem[2] <= '0;
            dataMem[3] <= '0;

            miss_wait_counter <= 0;
            state <= RESET_STATE;
        end
        else begin
            state <= next_state; // Update FSM state

            case (next_state)
                IDLE: begin
                    miss_wait_counter <= 0;
                end

                MISS: begin
                    if (state != MISS) begin
                        miss_wait_counter <= 2;
                    end
                    else if (miss_wait_counter > 0) begin
                        miss_wait_counter <= miss_wait_counter - 1;
                        if (miss_wait_counter == 1) begin
                            dataMem[index]  <= mem_dataOut;
                            tagMem[index]   <= tag_in;
                            validMem[index] <= 1'b1;
                        end
                    end
                end
                default: ;
            endcase
        end
    end

    always_comb begin
        if ((state == IDLE) && hit) begin
            // word 0 => bits [127:96]
            // word 1 => bits [95 :64]
            // word 2 => bits [63 :32]
            // word 3 => bits [31 : 0]
            unique case (offset)
                2'd0: data_out = dataMem[index][127 : 96];
                2'd1: data_out = dataMem[index][95  : 64];
                2'd2: data_out = dataMem[index][63  : 32];
                2'd3: data_out = dataMem[index][31  :  0];
            endcase
        end
        else begin
            // During miss or invalid line, data_out is not valid
            data_out = 32'h00000000;
        end
    end

endmodule
