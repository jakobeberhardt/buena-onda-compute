`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`timescale 1ns/1ps

module RISCVCPU_tb_imem_latency;

    logic clock;
    logic reset;

    // Cycle Counter
    reg [63:0] cycle_count;

    localparam ADDI_X1_X0_5 = 32'h00500093; // Example instruction: addi x1, x0, 5

    RISCVCPU dut (
        .clock(clock),
        .reset(reset)
    );

    reg test_pass;
    reg test_fail;
    reg [31:0] fetched_instruction;
    integer i;

    initial begin
        $dumpfile("RISCVCPU_tb_imem_latency.vcd");
        $dumpvars(0, RISCVCPU_tb_imem_latency);
    end

    initial begin
        clock = 0;
        forever #5 clock = ~clock; 
    end

    initial begin
        // Clear entire IMem to NOP (assuming NOP is 32'h00000013)
        for (i = 0; i < 1024; i = i + 1) begin
            dut.imem.IMem[i] = 32'h00000013; // NOP
        end

        dut.imem.IMem[0] = ADDI_X1_X0_5; // addi x1, x0, 5
    end

    initial begin
        cycle_count = 0;
        test_pass = 1;
        test_fail = 0;

        reset = 1;
        @(posedge clock);
        @(posedge clock);
        reset = 0;

        @(posedge clock);

        // Monitor mem_valid for the next 6 cycles
        for (i = 1; i <= 6; i = i + 1) begin
            @(posedge clock);
            cycle_count = cycle_count + 1;

            if (i <= 5) begin
                // For cycles 1 to 5, mem_valid should be false
                if (dut.iMem_valid !== 1'b0) begin
                    $display("Cycle %0d: FAIL - mem_valid should be FALSE, but is TRUE", i);
                    test_pass = 0;
                    test_fail = 1;
                end else begin
                    if (`DEBUG)
                        $display("Cycle %0d: PASS - mem_valid is FALSE as expected", i);
                end
            end else if (i == 6) begin
                // On cycle 6, mem_valid should be true and dataOut should have the instruction
                if (dut.iMem_valid !== 1'b1) begin
                    $display("Cycle %0d: FAIL - mem_valid should be TRUE, but is FALSE", i);
                    test_pass = 0;
                    test_fail = 1;
                end else begin
                    fetched_instruction = dut.iMem_data; 
                    if (fetched_instruction !== ADDI_X1_X0_5) begin
                        $display("Cycle %0d: FAIL - Fetched instruction = %h, expected = %h", 
                                 i, fetched_instruction, ADDI_X1_X0_5);
                        test_pass = 0;
                        test_fail = 1;
                    end else begin
                        if (`DEBUG)
                            $display("Cycle %0d: PASS - mem_valid is TRUE and instruction fetched correctly (%h)", 
                                     i, fetched_instruction);
                    end
                end
            end
        end

        if (test_pass && !test_fail)
            $display("[TEST PASS] IMem latency test passed successfully.");
        else
            $display("[TEST FAIL] IMem latency test failed.");

        $finish;
    end

    always @(posedge clock) begin
        if (`DEBUG) begin
            $display("***************************************************BEGIN OF CYCLE***************************************************");
            $display("Cycle: %0d", cycle_count);
            $display("Time: %0t | mem_valid = %0b | dataOut = %h", $time, dut.iMem_valid, dut.iMem_data);
            $display("***************************************************END OF CYCLE*****************************************************");
        end
    end

endmodule
