`timescale 1ns/1ps

module RISCVCPU_tb_buffer_sum;

    // -----------------------------
    // Clock & Reset
    // -----------------------------
    logic clock;
    logic reset;

    // Use 64-bit to avoid overflow in large sims
    reg [63:0] cycle_count;

    // Instantiate your CPU design
    // Adjust port names if your top-level differs
    RISCVCPU dut (
        .clock(clock),
        .reset(reset)
    );

    // Generate 100MHz clock (period=10ns)
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    initial begin
        $dumpfile("RISCVCPU_tb_buffer_sum.vcd");
        $dumpvars(0, RISCVCPU_tb_buffer_sum);
    end

    // -----------------------------
    // Instruction Memory Init
    // -----------------------------
    initial begin
        // Fill IMem with NOPs (addi x0,x0,0) to avoid garbage
        for (int i = 0; i < 256; i++) begin
            dut.imem.IMem[i] = 32'h00000013;  // NOP
        end

        // We’ll store the following program at IMem[0..11].
        //
        // Pseudocode:
        //   x1 = 0;            // sum
        //   x2 = 0;            // i
        //   x3 = 0;            // base pointer for a[]
        //   x4 = 128;          // limit (128)
        //
        // loop:
        //   lw   x5, 0(x3)     // x5 = a[i]
        //   add  x1, x1, x5    // sum += a[i]
        //   addi x3, x3, 4     // move pointer by 4 bytes
        //   addi x2, x2, 1     // i++
        //   beq  x2, x4, done  // if (i == 128) break
        //   jalr x0, 16(x0)    // uncond jump back to PC=16 (which is IMem[4]) 
        //
        // done:
        //   nop
        //   nop

        // 0: addi x1, x0, 0
        dut.imem.IMem[0] = 32'h00000093;  // x1 = 0
        // 1: addi x2, x0, 0
        dut.imem.IMem[1] = 32'h00000113;  // x2 = 0
        // 2: addi x3, x0, 0
        dut.imem.IMem[2] = 32'h00000193;  // x3 = 0
        // 3: addi x4, x0, 128
        dut.imem.IMem[3] = 32'h08000213;  // x4 = 128

        // 4: lw   x5, 0(x3)
        dut.imem.IMem[4] = 32'h0001a283;  // lw x5, 0(x3)
        // 5: add  x1, x1, x5
        dut.imem.IMem[5] = 32'h005080b3;  // add x1, x1, x5
        // 6: addi x3, x3, 4
        dut.imem.IMem[6] = 32'h00418193;  // addi x3, x3, 4
        // 7: addi x2, x2, 1
        dut.imem.IMem[7] = 32'h00110113;  // addi x2, x2, 1

        // 8: beq  x2, x4, +2 => jump to IMem[10] if (x2 == x4)
        dut.imem.IMem[8] = 32'h00410663;  // beq x2, x4, 2 instructions ahead
        // 9: jalr x0, 16(x0) => uncond jump back to address 16 decimal (IMem[4])
        dut.imem.IMem[9] = 32'h01000067;  // jalr x0, 16(x0)

        // 10: nop
        dut.imem.IMem[10] = 32'h00000013;
        // 11: nop
        dut.imem.IMem[11] = 32'h00000013;
        dut.imem.IMem[12] = 32'h00000013;
        dut.imem.IMem[13] = 32'h00000013;
    end

    // -----------------------------
    // Data Memory Init (a[128])
    // -----------------------------
    typedef bit [31:0] word_type;
    typedef bit [127:0] cache_data_type;

    // Temporary array to hold 32-bit words
    word_type temp_DMem_words [0:4095]; 
    initial begin
        // If your design has a main memory like:
        //   dut.mem_stage.main_memory.memArray[0..1023]
        // each entry is 128 bits (4x 32-bit words).
        // We'll store a[i] = i for i in [0..127].
        //
        // The address for a[i] = 4*i (bytes).
        // So a[0] is at address 0, a[1] at address 4, ...
        //
        // We must pack 4 words into each 128-bit memArray entry:
        //   memArray[line_index] = { word3, word2, word1, word0 }
        // where each word is 32 bits.
        //
        // line_index = i >> 2  (integer division by 4)
        // word_in_line = i & 3 (which word within that line)
        //
        // We do an example below:
        // for (int line = 0; line < 1024; line++) begin
        //     dut.mem_stage.main_memory.memArray[line] = 128'b0;
        // end

        // // Fill first 128 words with ascending data: a[i] = i
        // for (int i = 0; i < 128; i++) begin
        //     automatic int line_index     = i >> 2;    // i/4
        //     automatic int word_in_line   = i & 3;     // i%4
        //     // We build a 128-bit line by writing to the correct 32-bit slice
        //     // e.g. memArray[line_index][(word_in_line+1)*32-1 -: 32] = i
        //     case (word_in_line)
        //         0: dut.mem_stage.main_memory.memArray[line_index][ 31:  0] = i;
        //         1: dut.mem_stage.main_memory.memArray[line_index][ 63: 32] = i;
        //         2: dut.mem_stage.main_memory.memArray[line_index][ 95: 64] = i;
        //         3: dut.mem_stage.main_memory.memArray[line_index][127: 96] = i;
        //     endcase
        // end

        // Load 32-bit words from the data file
        $readmemh("testbench/data/dmem_sum.dat", temp_DMem_words);

        // Pack every four 32-bit words into one 128-bit block
        for (int i = 0; i < 1024; i++) begin
            dut.mem_stage.main_memory.memArray[i] = {temp_DMem_words[4*i + 3],
                                temp_DMem_words[4*i + 2],
                                temp_DMem_words[4*i + 1],
                                temp_DMem_words[4*i]};
        end
    end

    // -----------------------------
    // Main Test Control
    // -----------------------------
    initial begin
        cycle_count = 0;

        // Reset for a few cycles
        reset = 1;
        repeat (2) @(posedge clock);
        reset = 0;

        // Wait enough cycles for CPU to finish summing
        repeat (20000) @(posedge clock);

        $display("==== Final Register File ====");
        for (int i = 0; i < 10; i++) begin
            $display("x%0d = %0d", i, dut.regfile.Regs[i]);
        end

        // Sum of 0..127 is 8128
        check_reg(1, 8128);

        $finish;
    end

    // -----------------------------
    // Cycle Counting (Optional)
    // -----------------------------
    always @(posedge clock) begin
        cycle_count++;
        // For debug, you could print CPU signals here
        // $display("Cycle %0d: PC=%h IR=%h", cycle_count, dut.if_stage.PC, dut.if_id_bus_in.instruction);
    end

    // -----------------------------
    // Checker Task
    // -----------------------------
    task check_reg(input int regnum, input int expected);
        if (dut.regfile.Regs[regnum] == expected) begin
            $display("[PASS] x%0d = %0d (expected %0d)",
                     regnum, dut.regfile.Regs[regnum], expected);
        end else begin
            $display("[FAIL] x%0d = %0d (expected %0d)",
                     regnum, dut.regfile.Regs[regnum], expected);
        end
    endtask

endmodule
