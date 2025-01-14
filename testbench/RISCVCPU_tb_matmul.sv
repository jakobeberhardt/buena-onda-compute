`define DEBUG 0  // Set to 1 to enable debug prints, 0 to disable
`timescale 1ns/1ps

module RISCVCPU_tb_matmul;

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

    initial begin
        $dumpfile("RISCVCPU_tb_matmul.vcd");
        $dumpvars(0, RISCVCPU_tb_matmul);
    end

    typedef bit [31:0] word_type;

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
        $readmemh("testbench/data/matmul.dat", temp_DMem_words);

        // Pack every four 32-bit words into one 128-bit block
        for (int i = 0; i < 1024; i++) begin
            dut.mem_stage.main_memory.memArray[i] = {temp_DMem_words[4*i + 3],
                                temp_DMem_words[4*i + 2],
                                temp_DMem_words[4*i + 1],
                                temp_DMem_words[4*i]};
        end

        // -- Program: place instructions in IMem --
        //Testing Mat mul
        // Initialization of Registers and Constants
        // Initialization
        // Initialization of Registers and Constants
        /*dut.regfile.Regs[1] = 0; // x0 = 0
        dut.regfile.Regs[2] = 1024; // x0 = 0
        dut.regfile.Regs[3] = 2048; */
        dut.regfile.Regs[10] = -960; // x10 = -960


        // Initialize matrices and constants
        dut.imem.IMem[0]  = 32'h00000093; // ADDI x1, x0, 0    # x1: Base address of matrix C (result)
        dut.imem.IMem[1]  = 32'h40000113; // ADDI x2, x0, 1024   # x2: Base address of matrix A
        dut.imem.IMem[2]  = 32'h40000193; // ADDI x3, x0, 2048  # x3: Base address of matrix B
        dut.imem.IMem[3]  = 32'h01000213; // ADDI x4, x0, 16    # x4: Size of matrix (n=16)
        dut.imem.IMem[4]  = 32'h00000293; // ADDI x5, x0, 0    # x5: i = 0 (row counter)

        // Start of outer loop (i)
        dut.imem.IMem[5]  = 32'h00000313; // ADDI x6, x0, 0    # x6: j = 0 (column counter)

        // Start of middle loop (j)
        dut.imem.IMem[6]  = 32'h00000393; // ADDI x7, x0, 0    # x7: k = 0 (dot product counter)
        dut.imem.IMem[7]  = 32'h00000e13; // ADDI x28, x0, 0   # x28: Reset dot product accumulator

        // Start of inner loop (dot product calculation)
        dut.imem.IMem[8]  = 32'h00012f03; // LW x30, 0(x2)     # Load A[i][k] into x30
        dut.imem.IMem[9]  = 32'h0001af83; // LW x31, 0(x3)     # Load B[k][j] into x31
        dut.imem.IMem[10] = 32'h03ff0433; // MUL x8, x30, x31 # Multiply A[i][k] * B[k][j]
        dut.imem.IMem[11] = 32'h008e0e33; // ADD x28, x28, x8   # Accumulate dot product
        dut.imem.IMem[12] = 32'h00138393; // ADDI x7, x7, 1    # k++
        // Check inner loop condition
        dut.imem.IMem[13] = 32'h00438863; // BEQ x7, x4, 16     # If k == n, exit inner loop
        dut.imem.IMem[14] = 32'h00410113; // ADDI x2, x2, 4    # Move to next element in A's row
        dut.imem.IMem[15] = 32'h04018193; // ADDI x3, x3, 64   # Move to next element in B's column

        
        dut.imem.IMem[16] = 32'h02000067; // JALR x0, 32(x0)   # Jump back to inner loop start

        // Store result and prepare for next iteration
        dut.imem.IMem[17] = 32'h01c0a023; // SW x28, 0(x1)     # Store result in C[i][j]
        dut.imem.IMem[18] = 32'h00408093; // ADDI x1, x1, 4    # Move to next element in C
        dut.imem.IMem[19] = 32'hfc410113; // ADDI x2, x2, -60   # Reset A's row pointer (-(15*4))
        dut.imem.IMem[20] = 32'h00a181b3; // ADD x3, x3, x10 # Reset B's column pointer (-(16*15*4))
        dut.imem.IMem[21] = 32'h00130313; // ADDI x6, x6, 1    # j++
        // Check middle loop condition
        dut.imem.IMem[22] = 32'h00430663; // BEQ x6, x4, 12     # If j == n, exit middle loop
        dut.imem.IMem[23] = 32'h00418193; // ADDI x3, x3, 4    # Move to next column in B
        dut.imem.IMem[24] = 32'h01800067; // JALR x0, 24(x0)   # Jump back to middle loop start

        // Increment i and prepare for next row
        dut.imem.IMem[25] = 32'h00128293; // ADDI x5, x5, 1    # i++
        // Check outer loop condition
        dut.imem.IMem[26] = 32'h00428863; // BEQ x5, x4, 16     # If i == n, exit program
        dut.imem.IMem[27] = 32'h04010113; // ADDI x2, x2, 64    # Move to next row in A (16*4 bytes)
        dut.imem.IMem[28] = 32'hfc418193; // ADDI x3, x3, -60   # Reset column position in B (-(15*4))
        dut.imem.IMem[29] = 32'h01400067; // JALR x0, 20(x0)   # Jump back to outer loop start

        // Program completion
        dut.imem.IMem[30] = 32'h00000013; // NOP
        dut.imem.IMem[31] = 32'h0000007f; // Special instruction to drain cache to DMEM
        dut.imem.IMem[32] = 32'h0000007f; // Special instruction to drain cache to DMEM

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
        repeat (200000) @(posedge clock); 
        

        // Display Register Values After Execution
        $display("==== Final Register File ====");
        for (int i = 0; i <= 12; i = i + 1) begin
            $display("After execution, x%d = %d", i, dut.regfile.Regs[i]);
        end

        // Display Memory Contents
        print_mainMem();
        print_cacheMem();
        print_StoreBuffer();

        // Verify Key Registers
        check_results();

        // End Simulation
        $finish;
    end

    task automatic print_mainMem();
        // Print top 4 lines of memory, each line is 128 bits (4 x 32-bit words)
        $display("==== Final Memory ====");
        for (int i = 0; i < 16; i = i + 1) begin
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

    task automatic print_StoreBuffer();
        $display("==== Final Store Buffer ====");
        for (int i = 0; i < 4; i = i + 1) begin
            $display("StoreBuffer[%0d] = %0p", i, dut.mem_stage.sb.store_buf[i]);
        end
    endtask

    task automatic check_results();
        int pass_count = 0;
        int fail_count = 0;

        // We'll check only the registers we care about:
        // x1=5, x2=10, x3=10, x4=15, x5=15
        // Also check DMEM[0] == 5, DMEM[1] == 10, DMEM[2] == 15

        // Register Checks


        // lopp to check the rest of the memory using check_dmem
        check_dmem(1020,546176);
        check_dmem(0,21896);
        check_dmem(60,23936);





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

    task check_cache(input int addr, input int expected);
        automatic logic [31:0] cacheValue;
        automatic int word_in_line = (addr / 4) % 4;
        case (word_in_line) 
            0: cacheValue = dut.mem_stage.cache_controller.cdata.data_mem[addr/16][31:0];
            1: cacheValue = dut.mem_stage.cache_controller.cdata.data_mem[addr/16][63:32];
            2: cacheValue = dut.mem_stage.cache_controller.cdata.data_mem[addr/16][95:64];
            3: cacheValue = dut.mem_stage.cache_controller.cdata.data_mem[addr/16][127:96];
        endcase
        if (cacheValue == expected) begin
            $display("Cache[%0d] PASS: got %0d, expected %0d", 
                     addr, cacheValue, expected);
        end else begin
            $display("Cache[%0d] FAIL: got %0d, expected %0d", 
                     addr, cacheValue, expected);
        end
    endtask

    task check_storebuf(input int addr, input int expected);
        if (dut.mem_stage.sb.store_buf[addr] == expected) begin
            $display("StoreBuffer[%0d] PASS: got %0d, expected %0d", 
                     addr, dut.mem_stage.sb.store_buf[addr], expected);
        end else begin
            $display("StoreBuffer[%0d] FAIL: got %0d, expected %0d", 
                     addr, dut.mem_stage.sb.store_buf[addr], expected);
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
