module ITLB(
    input  logic         clock,
    input  logic         reset,
    input  logic [31:0]  virt_addr_in,
    output logic [31:0]  phys_addr_out,
    output logic         iTLB_stall
);

    typedef enum logic [1:0] {
        IDLE,
        FAULT
    } state_t;

    state_t curr_state, next_state;
    logic        tlb_valid;
    logic [21:0] tlb_vpn;   // top bits of the stored virtual address
    logic [21:0] tlb_ppn;   // top bits of the stored physical address
    logic [3:0] fault_counter;
    wire [9:0] page_offset = virt_addr_in[9:0];

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            // Start in FAULT so we keep stall high
            curr_state     <= FAULT;
            tlb_valid      <= 1'b0;     
            fault_counter  <= 4'd0;
            tlb_vpn        <= 22'd0;
            tlb_ppn        <= 22'd0;
        end
        else begin
            curr_state <= next_state;

            case (curr_state)
                IDLE: begin
                end

                FAULT: begin
                    if (fault_counter < 4'd10) begin
                        fault_counter <= fault_counter + 4'd1;
                    end
                    else begin
                        tlb_valid     <= 1'b1;
                        tlb_vpn       <= virt_addr_in[31:10]; 
                        tlb_ppn       <= virt_addr_in[31:10]; // example 1:1 mapping, could add an offset
                        fault_counter <= 4'd0;
                    end
                end
            endcase
        end
    end

    always_comb begin
        // Defaults
        next_state   = curr_state;
        iTLB_stall   = 1'b0;  // default low, override as needed

        case (curr_state)
            IDLE: begin
                // If TLB not valid or does not match, we need to refill => stall
                if (!tlb_valid || (virt_addr_in[31:10] != tlb_vpn)) begin
                    next_state   = FAULT;
                    iTLB_stall   = 1'b1;
                end
            end

            FAULT: begin
                // Remain in FAULT until fault_counter hits 10
                iTLB_stall = 1'b1;
                if (fault_counter == 4'd10) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Physical address generation:
    assign phys_addr_out = (tlb_valid && (virt_addr_in[31:10] == tlb_vpn))
                           ? {tlb_ppn, page_offset} + 4'd0000
                           : 32'hDEAD_BEEF;
endmodule
