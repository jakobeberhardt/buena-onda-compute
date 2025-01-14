module DTLB(
    input  logic         clock,
    input  logic         reset,
    input  logic [31:0]  virt_data_addr_in,
    output logic [31:0]  phys_data_addr_out,
    output logic         dTLB_stall
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
    wire [9:0] page_offset = virt_data_addr_in[9:0];

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
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
                        tlb_vpn       <= virt_data_addr_in[31:10]; 
                        tlb_ppn       <= virt_data_addr_in[31:10];
                        fault_counter <= 4'd0;
                    end
                end
            endcase
        end
    end

    always_comb begin
        // Defaults
        next_state   = curr_state;
        dTLB_stall   = 1'b0;  
        case (curr_state)
            IDLE: begin
                if (!tlb_valid || (virt_data_addr_in[31:10] != tlb_vpn)) begin
                    next_state   = FAULT;
                    dTLB_stall   = 1'b1;
                end
            end

            FAULT: begin
                dTLB_stall = 1'b1;
                if (fault_counter == 4'd10) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

        assign phys_data_addr_out = (tlb_valid && (virt_data_addr_in[31:10] == tlb_vpn))
                                ? {tlb_ppn, page_offset}
                                : 32'hDEAD_BEEF; 
endmodule
