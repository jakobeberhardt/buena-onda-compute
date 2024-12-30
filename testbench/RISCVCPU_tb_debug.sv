`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`timescale 1ns/1ps

module RISCVCPU_tb_debug;

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

    
    // ----------------------------------
    // IMem and DMem Initialization
    // ----------------------------------
    initial begin
        // Clear entire IMem to 0 just in case
       /* for (int i = 0; i < 256; i++) begin
            dut.imem.IMem[i] = 32'h00000013; // default = NOP
        end*/

        dut.regfile.Regs[2] = 32'hffff00ff;
        dut.regfile.Regs[1] = 32'h00000001;

        // -- Program: place instructions in IMem --
        dut.imem.IMem[0] = 32'h00000083; // lb x1, 0(x0)
        dut.imem.IMem[1] = 32'h00200223; // sb x2, 4(x0)
        //dut.imem.IMem[0] = 32'h001080b3; // add x1, x1, x1
        //dut.imem.IMem[1] = 32'h001080b3; // add x1, x1, x1

        
        // Load DMem
        $readmemh("testbench/data/dmem.dat", dut.dmem.DMem);
        //dut.dmem.DMem[0] = 10;

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
        repeat (30) @(posedge clock); 
        

        // Display Register Values After Execution
        $display("==== Final Register File ====");
        for (int i = 0; i <= 12; i = i + 1) begin
            $display("After execution, x%0d = %0d", i, dut.regfile.Regs[i]);
        end

        //print top 5 values of DMEM
        for (int i = 0; i < 10; i = i + 1) begin
            $display("DMEM[%0d] = %0d", i, dut.dmem.DMem[i]);
        end


        //$display("DMEM[0] got %0d, expected 15", dut.dmem.DMem[1]);

        // Verify Key Registers
        // check_results();

        // End Simulation
        $finish;
    end




    // Always Block to Monitor and Display Cycle Information
    always @(posedge clock) begin
        // Increment Cycle Counter
        cycle_count = cycle_count + 1;

        // Display Cycle Information 
        if (`DEBUG) begin
            $display("Cycle: %0d", cycle_count - 2);
            $display("Time: %0t | PC = %0d, IR(IF-ID stage) = %h", $time, dut.if_stage.PC, dut.if_id_bus_in.instruction);
            $display("Time: %0t | PC = %0d, IR(ID-EX stage) = %p", $time, dut.if_stage.PC, dut.id_ex_bus_in);
            $display("Time: %0t | PC = %0d, IR(EX-MEM stage) = %p", $time, dut.if_stage.PC, dut.ex_mem_bus_in);
            $display("Time: %0t | PC = %0d, IR(MEM-WB stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_in);
            $display("Time: %0t | PC = %0d, IR(MEM OUT stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_out);
            $display("Time: %0t | PC = %0d, Control Signal = %p", $time, dut.if_stage.PC, dut.ctrl_signals);
            $display("***************************************************END OF CYCLE***************************************************");
        end
    end

endmodule
