`define DEBUG 1  // Set to 1 to enable debug prints, 0 to disable
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

    typedef bit [31:0] word_type;
    typedef bit [127:0] cache_data_type;

    // Temporary array to hold 32-bit words
    word_type temp_DMem_words [0:4095]; 
    
    // ----------------------------------
    // IMem and DMem Initialization
    // ----------------------------------
    initial begin
        // Clear entire IMem to 0 just in case
       for (int i = 0; i < 256; i++) begin
            dut.imem.IMem[i] = 32'h00000013; // default = NOP
        end


        // -- Program: place instructions in IMem --
        ///dut.imem.IMem[0] = 32'h00002083; // lw x1, 0(x0)
        //dut.imem.IMem[1] = 32'h00402103; // lw x2, 4(x0)
        //dut.imem.IMem[1] = 32'h00502023; // sw   x5, 0(x0)
        //debugging branch
        /*dut.imem.IMem[0] = 32'h00002083; // lw x1, 0(x0)
        dut.imem.IMem[1] = 32'h00a00113; // addi x2, x0, 10
        dut.imem.IMem[2] = 32'h00010263; // beq x2, x0, 4
        dut.imem.IMem[3] = 32'h002081b3; // add x3, x1, x2*/

        //Debuging load hazard
        /*dut.imem.IMem[0] = 32'h00002083; // lw x1, 0(x0)
        dut.imem.IMem[1] = 32'h00108133; // add  x2, x1, x1
        dut.imem.IMem[2] = 32'h00000013; // NOP
        dut.imem.IMem[3] = 32'h00202223; // sw   x2, 4(x0)
        dut.imem.IMem[4] = 32'h00402183; // lw   x3, 4(x0)*/

        dut.imem.IMem[0] = 32'h00c00293; // addi x5, x0, 12
        dut.imem.IMem[1] = 32'h0052a023; // sw x5, 0(x5)

        dut.imem.IMem[5] = 32'h0000007f; // SPecial Instruction to Drain cache to DMEM


        
        
        // Load DMem
        // Load 32-bit words from the data file
        $readmemh("testbench/data/dmem.dat", temp_DMem_words);

        // Pack every four 32-bit words into one 128-bit block
        for (int i = 0; i < 1024; i++) begin
            dut.mem_stage.main_memory.memArray[i] = {temp_DMem_words[4*i + 3],
                                temp_DMem_words[4*i + 2],
                                temp_DMem_words[4*i + 1],
                                temp_DMem_words[4*i]};
        end

        dut.mem_stage.main_memory.memArray[0][31:0] = 32'h00000005; // DMEM[0][Word0] = 5

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
        
        print_mainMem();
        print_cacheMem();


        // Display Register Values After Execution
        $display("==== Final Register File ====");
        for (int i = 0; i <= 12; i = i + 1) begin
            $display("After execution, x%0d = %0d", i, dut.regfile.Regs[i]);
        end



    

        // End Simulation
        $finish;
    end

    task automatic print_mainMem();
        // Print top 4 lines of memory, each line is 128 bits (4 x 32-bit words)
        $display("==== Final Memory ====");
        for (int i = 0; i < 4; i = i + 1) begin
            for (int j = 0; j < 4; j = j + 1) begin
                // Declare variables as automatic to ensure they are stack-based
                automatic int msb;
                automatic int lsb;
                automatic logic [31:0] current_word;
                msb = (j + 1) * 32 - 1;
                lsb = j * 32;
                
                // Calculate the bit range for the current word using a case statement
                case (j)
                    0: begin
                        current_word = dut.mem_stage.main_memory.memArray[i][31:0];
                    end
                    1: begin
                        current_word = dut.mem_stage.main_memory.memArray[i][63:32];
                    end
                    2: begin
                        current_word = dut.mem_stage.main_memory.memArray[i][95:64];
                    end
                    3: begin
                        current_word = dut.mem_stage.main_memory.memArray[i][127:96];
                    end
                endcase
                // Display the word with proper indexing
                $display("memArray[%0d] word%0d [%0d:%0d] = %0d", 
                        (i * 4 + j) * 4, j, msb, lsb, current_word);
            end
        end
    endtask

    task automatic print_cacheMem();
        // Print top 4 lines of memory, each line is 128 bits (4 x 32-bit words)
        $display("==== Final Cache Memory ====");
        for (int i = 0; i < 4; i = i + 1) begin
            for (int j = 0; j < 4; j = j + 1) begin
                // Declare variables as automatic to ensure they are stack-based
                automatic int msb;
                automatic int lsb;
                automatic logic [31:0] current_word;
                msb = (j + 1) * 32 - 1;
                lsb = j * 32;
                
                // Calculate the bit range for the current word using a case statement
                case (j)
                    0: begin
                        current_word = dut.mem_stage.cache_controller.cdata.data_mem[i][31:0];
                    end
                    1: begin
                        current_word = dut.mem_stage.cache_controller.cdata.data_mem[i][63:32];
                    end
                    2: begin
                        current_word = dut.mem_stage.cache_controller.cdata.data_mem[i][95:64];
                    end
                    3: begin
                        current_word = dut.mem_stage.cache_controller.cdata.data_mem[i][127:96];
                    end
                endcase
                // Display the word with proper indexing
                $display("CacheArray[%0d] word%0d [%0d:%0d] = %0d", 
                        (i * 4 + j) * 4, j, msb, lsb, current_word);
            end
        end
    endtask




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
            $display("Time: %0t | PC = %0d, IR(EX-MEM OUT stage) = %p", $time, dut.if_stage.PC, dut.ex_mem_bus_out);
            $display("Time: %0t | PC = %0d, IR(MEM-WB stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_in);
            $display("Time: %0t | PC = %0d, IR(MEM OUT stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_out);
            $display("Time: %0t | PC = %0d, Control Signal = %p", $time, dut.if_stage.PC, dut.ctrl_signals);
            $display("***************************************************END OF CYCLE***************************************************");
        end
    end

endmodule
