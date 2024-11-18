# Makefile for RISCVCPU simulation

# Compiler and tools
IVERILOG = iverilog
VVP = vvp
WAVEVIEWER = gtkwave

# Source files
SRC = RISCVCPU.v
TB = RISCVCPU_tb.v
OUT = RISCVCPU_tb

# Default target to compile and run simulation
all: $(OUT).vcd

$(OUT).vcd: $(SRC) $(TB) imem.dat
	$(IVERILOG) -o $(OUT) $(TB) $(SRC)
	$(VVP) $(OUT)

# Target to open waveforms in GTKWave
view: $(OUT).vcd
	$(WAVEVIEWER) $(OUT).vcd &

# Clean up generated files
clean:
	rm -f $(OUT) $(OUT).vcd
