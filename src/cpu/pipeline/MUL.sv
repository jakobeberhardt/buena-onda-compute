module MUL(
    input  logic         clock,
    input  logic         reset,

    // Inputs to start multiplication
    input  logic [31:0]  A_in,
    input  logic [31:0]  B_in,
    input  logic         valid_in,   // Asserts when A_in/B_in are valid for new multiply

    // 5 pipeline-stage result
    output logic [31:0]  result_out,
    output logic         valid_out,  // Asserts when result_out is valid

    // Stall signal
    output logic         stall_out   // Request pipeline stall if we're still busy
);

    // We'll artificially pipeline the multiply across 5 cycles:
    // - On the cycle valid_in=1, we capture A_in, B_in in M1.
    // - Then M2..M5 produce final result.
    // We also maintain a 4-cycle "stall counter" so the pipeline knows we’re busy.

    // For simplicity, we’ll keep a register for each stage.
    logic [31:0] stage1_value;
    logic [31:0] stage2_value;
    logic [31:0] stage3_value;
    logic [31:0] stage4_value;
    logic [31:0] stage5_value;

    // Valid bits for each stage
    logic stage1_valid, stage2_valid, stage3_valid, stage4_valid, stage5_valid;

    // A simple 3-bit counter for 4-cycle stall
    //  - On the cycle valid_in=1, we set mul_stall_counter = 4
    //  - Each cycle we decrement until 0
    //  - While > 0, stall_out = 1
    logic [2:0] mul_stall_counter;

    //-------------------------------------------------------------------------
    // Stall counter logic
    //-------------------------------------------------------------------------
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            mul_stall_counter <= 3'd0;
        end
        else begin
            if (valid_in) begin
                // Start a new multiply => set counter to 4
                mul_stall_counter <= 3'd4;
            end
            else if (mul_stall_counter > 0) begin
                // Count down each cycle
                mul_stall_counter <= mul_stall_counter - 1;
            end
        end
    end

    // assert stall_out as long as mul_stall_counter > 0
    assign stall_out = (mul_stall_counter > 0);

    //-------------------------------------------------------------------------
    // Pipeline for the 5-cycle multiplication
    // For demonstration, we’ll just do A_in*B_in in stage1,
    // then pass it through M2..M5. In a real design, you'd do partial products.
    //-------------------------------------------------------------------------

    // Stage M1
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            stage1_value <= 32'd0;
            stage1_valid <= 1'b0;
        end
        else begin
            if (valid_in) begin
                // Start the multiply
                stage1_value <= A_in * B_in;  // single-cycle multiply, artificially pipelined
                stage1_valid <= 1'b1;
            end
            else begin
                stage1_value <= 32'd0;
                stage1_valid <= 1'b0;
            end
        end
    end

    // Stage M2
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            stage2_value <= 32'd0;
            stage2_valid <= 1'b0;
        end
        else begin
            stage2_value <= stage1_value;
            stage2_valid <= stage1_valid;
        end
    end

    // Stage M3
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            stage3_value <= 32'd0;
            stage3_valid <= 1'b0;
        end
        else begin
            stage3_value <= stage2_value;
            stage3_valid <= stage2_valid;
        end
    end

    // Stage M4
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            stage4_value <= 32'd0;
            stage4_valid <= 1'b0;
        end
        else begin
            stage4_value <= stage3_value;
            stage4_valid <= stage3_valid;
        end
    end

    // Stage M5
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            stage5_value <= 32'd0;
            stage5_valid <= 1'b0;
        end
        else begin
            stage5_value <= stage4_value;
            stage5_valid <= stage4_valid;
        end
    end

    // Final output
    assign result_out = stage5_value;
    assign valid_out  = stage5_valid;

endmodule
