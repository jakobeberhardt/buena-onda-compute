`timescale 1ns/1ps

module RISCVCPU_tb;

    reg clock;
    integer i;

    // Instantiate the CPU
    RISCVCPU cpu(.clock(clock));

    // Clock generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // Clock period of 10 time units
    end

    initial begin
        // Initialize instruction memory with the given instructions

        // Since ALUop is 7'b0010011 in the module (for I-type instructions),
        // but we are using R-type add instructions, we will encode the R-type
        // add instructions using the ALUop opcode as per the module.

        // Instruction format for R-type (as per standard RISC-V, but with opcode as ALUop):
        // [31:25] funct7 | [24:20] rs2 | [19:15] rs1 | [14:12] funct3 | [11:7] rd | [6:0] opcode

        // Instruction 1: add x1, x10, x11
        cpu.IMemory[0] = {7'b0000000, 5'd11, 5'd10, 3'b000, 5'd1, 7'b0010011};

        // Instruction 2: add x2, x12, x13
        cpu.IMemory[1] = {7'b0000000, 5'd13, 5'd12, 3'b000, 5'd2, 7'b0010011};

        // Instruction 3: add x3, x1, x2
        cpu.IMemory[2] = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0010011};

        // Instruction 4: add x4, x3, x1
        cpu.IMemory[3] = {7'b0000000, 5'd1, 5'd3, 3'b000, 5'd4, 7'b0010011};

        // Fill the rest of instruction memory with NOPs
        for (i = 4; i < 1024; i = i + 1)
            cpu.IMemory[i] = 32'h00000013; // NOP instruction

        // Initialize register values
        for (i = 0; i < 32; i = i + 1)
            cpu.Regs[i] = i; // Registers x0 to x31 initialized to their index

        // Run the simulation for enough clock cycles
        #200; // Adjust as needed based on pipeline depth and instruction count

        // Print the register values after execution
        $display("Register values after execution:");
        for (i = 0; i < 32; i = i + 1)
            $display("x%0d = %0d", i, cpu.Regs[i]);

        $finish;
    end
endmodule
