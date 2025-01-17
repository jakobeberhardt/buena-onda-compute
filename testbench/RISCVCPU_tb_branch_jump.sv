`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`timescale 1ns/1ps

module RISCVCPU_tb_branch_jump;

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

        // Load 32-bit words from the data file
        $readmemh("testbench/data/dmem.dat", temp_DMem_words);

        // Pack every four 32-bit words into one 128-bit block
        for (int i = 0; i < 1024; i++) begin
            dut.mem_stage.main_memory.memArray[i] = {temp_DMem_words[4*i + 3],
                                temp_DMem_words[4*i + 2],
                                temp_DMem_words[4*i + 1],
                                temp_DMem_words[4*i]};
        end

        //dut.regfile.Regs[7] = 64; 

        // -- Program: place instructions in IMem --
        dut.imem.IMem[0] = 32'h00002083; // lw x1, 0(x0)
        dut.imem.IMem[1] = 32'h00a00113; // addi x2, x0, 10
        dut.imem.IMem[2] = 32'h00010263; // beq x2, x0, 4
        dut.imem.IMem[3] = 32'h002081b3; // add x3, x1, x2
        dut.imem.IMem[4] = 32'h00218263; // beq x3, x2, 4
        dut.imem.IMem[5] = 32'h40118233; // sub x4, x3, x1
        dut.imem.IMem[6] = 32'h00402223; // sw x4, 4(x0) 
        dut.imem.IMem[7] = 32'h00402283; // lw x5, 4(x0)
        dut.imem.IMem[8] = 32'h00228263; // beq x5, x2, 4
        dut.imem.IMem[9] = 32'h3e700313; // addi x6, x0, 9999
        dut.imem.IMem[10] = 32'h00128333; // add x6, x5, x1
        dut.imem.IMem[11] = 32'h04000393; // addi x7, x0, 64
        dut.imem.IMem[12] = 32'h00038467; // jalr x8, 0(x7)
        dut.imem.IMem[13] = 32'h00000013; // NOP
        dut.imem.IMem[14] = 32'h00000013; // NOP
        dut.imem.IMem[15] = 32'h00000013; // NOP
        // Code at address 16 => PC=16*4=64
        dut.imem.IMem[16] = 32'h4d200493; // addi x9, x0, 1234
        dut.imem.IMem[17] = 32'h00902423; // sw x9, 8(x0)

        //force cache data into main memory by writing exact lines of cache memory
        //Just For testing purposes
        dut.imem.IMem[18] = 32'h0000007f; // SPecial Instruction to Drain cache to DMEM
        dut.imem.IMem[19] = 32'h0000007f; // SPecial Instruction to Drain cache to DMEM


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
        repeat (500) @(posedge clock); 
        

        // Display Register Values After Execution
        $display("==== Final Register File ====");
        for (int i = 0; i <= 12; i = i + 1) begin
            $display("After execution, x%d = %d", i, dut.regfile.Regs[i]);
        end

        // Print Memory
        print_mainMem();
        print_cacheMem();


        // Verify Key Registers
        check_results();

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

     task automatic check_results();
        int pass_count = 0;
        int fail_count = 0;

        // We'll check only the registers we care about:


        check_reg(1,  5); // load x1, 0(x0)
        check_reg(2, 10); // (stored by "addi x2, x0, 10")
        check_reg(3, 15); // (stored by "add x3, x1, x2"), (x1 + x2 = 5 + 10)
        check_reg(4, 10); // (stored by "sub x4, x3, x1"), (x3 - x1 = 15 - 5)
        check_reg(5, 10); // (stored by "lw x5, 4(x0)"), which is 10
        check_reg(6, 15); // (stored by "add x6, x5, x1"), (x5 + x1 = 10 + 5)
        check_reg(7, 64); // (stored by "addi x7, x0, 64")
        check_reg(9, 1234); //(addi x9, x0, 1234 at PC=64 after the jalr)

        check_dmem(0, 5); //(initial data, remains unchanged)
        check_dmem(4, 10); // (stored by "sw x4, 4(x0)")
        check_dmem(8, 1234); //1234 (stored at the jump target "sw x9, 8(x0)")
        

        if (fail_count == 0)
            $display("[TEST PASS] All checks passed!");
        else
            $display("[TEST FAIL] %0d passes, %0d fails.", pass_count, fail_count);
    endtask

    task check_dmem(input int addr, input int expected);
        automatic logic [31:0] memValue;
        automatic int word_in_line = (addr / 4) % 4;
        case (word_in_line) 
            0: memValue = dut.mem_stage.main_memory.memArray[addr/16][31:0];
            1: memValue = dut.mem_stage.main_memory.memArray[addr/16][63:32];
            2: memValue = dut.mem_stage.main_memory.memArray[addr/16][95:64];
            3: memValue = dut.mem_stage.main_memory.memArray[addr/16][127:96];
        endcase
        if (memValue == expected) begin
            $display("DMEM[%0d] PASS: got %0d, expected %0d", 
                     addr, memValue, expected);
        end else begin
            $display("DMEM[%0d] FAIL: got %0d, expected %0d", 
                     addr, memValue, expected);
        end
    endtask

    // Helper task to check a single register
    task check_reg(input int regnum, input int expected);
        if (dut.regfile.Regs[regnum] == expected) begin
            $display("x%0d PASS: got %0d, expected %0d", 
                     regnum, dut.regfile.Regs[regnum], expected);
        end else begin
            $display("x%0d FAIL: got %0d, expected %0d", 
                     regnum, dut.regfile.Regs[regnum], expected);
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
            $display("Time: %0t | PC = %0d, IR(MEM-WB stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_in);
            $display("Time: %0t | PC = %0d, IR(MEM OUT stage) = %p", $time, dut.if_stage.PC, dut.mem_wb_bus_out);
            $display("Time: %0t | PC = %0d, Control Signal = %p", $time, dut.if_stage.PC, dut.ctrl_signals);
            $display("***************************************************END OF CYCLE***************************************************");
        end
    end

endmodule
