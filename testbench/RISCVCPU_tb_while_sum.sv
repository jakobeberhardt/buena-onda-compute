`timescale 1ns/1ps

module RISCVCPU_tb_while_sum;

    logic clock;
    logic reset;

    reg [63:0] cycle_count;

    RISCVCPU dut (
        .clock(clock),
        .reset(reset)
    );

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // -----------------------------
    // Instruction Memory Init
    // -----------------------------
    initial begin
        for (int i = 0; i < 256; i++) begin
            dut.imem.IMem[i] = 32'h00000013; 
        end

        //   x1 = 0;          # sum
        //   x2 = 0;          # i
        //   x3 = 65;         
        // loop:
        //   x1 = x1 + x2;    # sum += i
        //   x2 = x2 + 1;     # i++
        //   beq x2, x3, done # if (i == 65) goto done
        //   beq x0, x0, loop # unconditional jump back to loop
        // done:
        //   nop
        //   nop

        // [0] addi x1, x0, 0  (x1=0)
        dut.imem.IMem[0] = 32'h00000093; 
        // [1] addi x2, x0, 0  (x2=0)
        dut.imem.IMem[1] = 32'h00000113;
        // [2] addi x3, x0, 65 (x3=65)
        dut.imem.IMem[2] = 32'h04100193;

        // loop:
        // [3] add x1, x1, x2   (sum += i)
        dut.imem.IMem[3] = 32'h002080b3;
        // [4] addi x2, x2, 1   (i++)
        dut.imem.IMem[4] = 32'h00110113;
        // [5] beq x2, x3, +3   -> jump to [8] if x2 == x3
        dut.imem.IMem[5] = 32'h00310663; 
        // [6]jalr x0, 12(x0)   -> jump back to [3], unconditional
        dut.imem.IMem[6] = 32'h00c00067;

        // done:
        // [7] nop
        dut.imem.IMem[7] = 32'h00000013;
        // [8] nop
        dut.imem.IMem[8] = 32'h00000013;
		dut.imem.IMem[9] = 32'h00000013;
		dut.imem.IMem[10] = 32'h00000013;
    end

    initial begin
        cycle_count = 0;

        // Apply Reset for a few cycles
        reset = 1;
        repeat (2) @(posedge clock);
        reset = 0;

        repeat (2000) @(posedge clock);

        $display("==== Final Register File ====");
        for (int i = 0; i < 10; i++) begin
            $display("x%0d = %0d", i, dut.regfile.Regs[i]);
        end

        // Check result: x1 should hold 2080
        check_reg(1, 2080);

        $finish;
    end

    always @(posedge clock) begin
        cycle_count++;
        // $display("Cycle %0d: PC=%h IR=%h", cycle_count, dut.if_stage.PC, dut.if_id_bus_in.instruction);
    end


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
