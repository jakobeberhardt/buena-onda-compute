`timescale 1ns/1ps

module RISCVCPU_tb_load_hazard;

    // Clock and Reset Signals
    logic clock;
    logic reset;

    // Cycle Counter (Using 64-bit to prevent overflow)
    reg [63:0] cycle_count;

    // Instantiate the DUT (Design Under Test)
    RISCVCPU dut (
        .clock(clock),
        .reset(reset)
    );

    // Clock Generation: 10ns Period (100MHz)
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // Toggle clock every 5ns
    end

    // Initial Block for Reset and Simulation Control
    initial begin
        // Initialize Cycle Counter
        cycle_count = 0;

        // Apply Reset
        reset = 1;
        repeat (2) @(posedge clock); // Hold reset for 2 clock cycles
        reset = 0;

        // Run Simulation for Sufficient Cycles to Execute Instructions
        // Instructions:
        // 1. addi x1, x0, 5
        // 2. addi x2, x0, 3
        // 3. add x3, x1, x2
        // Expected Outcome: x3 = 8 after execution

        repeat (10) @(posedge clock); // Wait for 8 clock cycles
         $readmemh("testbench/data/imem.dat", dut.imem.IMem);
        $readmemh("testbench/data/dmem.dat", dut.dmem.DMem);

        // Display Register Values After Execution
        // Assuming RegFile is accessible as dut.regfile.Regs
        // x3 should contain the value 8
        for (int i = 0; i <= 12; i = i + 1) begin
            $display("After execution, x%d = %d", i, dut.regfile.Regs[i]);
        end

        // End Simulation
        $finish;
    end

    // Always Block to Monitor and Display Cycle Information
    always @(posedge clock) begin
        // Increment Cycle Counter
        cycle_count = cycle_count + 1;

        // Display Cycle Information
        $display("***************************************************BEGIN OF CYCLE***************************************************");
        $display("Cycle: %0d", cycle_count - 2);
        $display("Time: %0t | PC = %h, IR(IF stage) = %h", $time, dut.if_stage.PC, dut.if_id_bus_in.instruction);
        $display("Time: %0t | PC = %h, IR(ID stage) = %p", $time, dut.if_stage.PC, dut.id_ex_bus_in);
        $display("Time: %0t | PC = %h, IR(EX stage) = %p", $time, dut.if_stage.PC, dut.ex_mem_bus_in);
        $display("Time: %0t | PC = %h, IR(MEM stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_in);
        $display("Time: %0t | PC = %h, IR(MEM OUT stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_out);
        $display("Time: %0t | PC = %h, Control Signal = %p", $time, dut.if_stage.PC, dut.ctrl_signals);
        //$display("***************************************************END OF CYCLE***************************************************");
    end

endmodule
