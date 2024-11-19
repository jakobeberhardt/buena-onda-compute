# Makefile for RISCVCPU project

# Compiler and tools
IVERILOG   = iverilog
VVP        = vvp
GTKWAVE    = gtkwave

# Source files
SRC        = RISCVCPU.v

# Testbenches
TB_STANDARD   = RISCVCPU_tb.v
TB_TESTCASES  = RISCVCPU_test.v

# Output executable names
OUT_STANDARD  = RISCVCPU_tb
OUT_TESTCASES = RISCVCPU_test

# Default target: Build the project
all: build

# Build the project (syntax check of RISCVCPU module)
build: $(SRC)
	@echo "Building RISCVCPU module..."
	$(IVERILOG) -o /dev/null -s RISCVCPU $(SRC)
	@echo "Build complete."

# Run the standard testbench and open GTKWave
wave: $(OUT_STANDARD).vcd
	@echo "Running standard testbench and opening GTKWave..."
	$(GTKWAVE) $(OUT_STANDARD).vcd &

$(OUT_STANDARD).vcd: $(SRC) $(TB_STANDARD)
	$(IVERILOG) -o $(OUT_STANDARD) $(TB_STANDARD) $(SRC)
	$(VVP) $(OUT_STANDARD)

# Run the testcases testbench
test: $(OUT_TESTCASES).vcd
	@echo "Running testcases testbench..."
	$(VVP) $(OUT_TESTCASES)

$(OUT_TESTCASES).vcd: $(SRC) $(TB_TESTCASES)
	$(IVERILOG) -o $(OUT_TESTCASES) $(TB_TESTCASES) $(SRC)
	$(VVP) $(OUT_TESTCASES)

# Clean up generated files
clean:
	rm -f $(OUT_STANDARD) $(OUT_STANDARD).vcd
	rm -f $(OUT_TESTCASES) $(OUT_TESTCASES).vcd
	@echo "Cleaned up generated files."
