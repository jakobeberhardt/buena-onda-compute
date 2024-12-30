# Makefile for RISCVCPU Project

# -------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------

# Directories
SRC_DIR := src
TB_DIR := testbench
LIB_DIR := work

# Simulator Commands
VLIB := vlib
VLOG := vlog
VSIM := vsim

# Source Files: All .sv and .v files in src/ and subdirectories
SRCS := $(shell find $(SRC_DIR) -type f \( -name "*.sv" \))

# Testbench Files: RISCVCPU_tb_*.sv and RISCVCPU_tb_*.v in testbench/
TB_FILES := $(shell find $(TB_DIR) -type f \( -name "RISCVCPU_tb_*.sv" \))

# Check if TB_FILES is empty
ifeq ($(TB_FILES),)
    $(error No testbench files found in $(TB_DIR) matching RISCVCPU_tb_*.sv or RISCVCPU_tb_*.v)
endif

# Testbench Names: Remove path and extension
TB_NAMES := $(basename $(notdir $(TB_FILES)))

# Simulation Options
VSIM_OPTS := -c -do "log -r /*; run -all; quit"

# -------------------------------------------------------------------
# Default Target
# -------------------------------------------------------------------

all: run_all

# -------------------------------------------------------------------
# Targets
# -------------------------------------------------------------------

# Create Simulation Library
$(LIB_DIR):
	@echo "Creating simulation library: $(LIB_DIR)"
	$(VLIB) $(LIB_DIR)

# Compile Source Files
compile_src: $(LIB_DIR)
	@echo "Compiling source files..."
	$(VLOG) +acc $(SRCS)

# Compile Testbench Files
compile_tbs: compile_src
	@echo "Compiling testbench files..."
	$(VLOG) +acc $(TB_FILES)

# Run All Testbenches
run_all: compile_tbs
	@echo "Running all testbenches..."
	@for tb in $(TB_NAMES); do \
		echo "----------------------------------------"; \
		echo "Running testbench: $$tb"; \
		$(VSIM) $(VSIM_OPTS) $$tb; \
	done
	@echo "All testbenches completed."

# Run a Specific Testbench
# Usage: make run TB=RISCVCPU_tb_basic
run:
ifndef TB
	$(error TB is not set. Usage: make run TB=Testbench_Name)
endif
	@echo "Running testbench: $(TB)"
	$(VSIM) $(VSIM_OPTS) $(TB)

# Clean Simulation Library
clean:
	@echo "Cleaning simulation library..."
	rm -rf $(LIB_DIR)/* *.vcd
	@echo "Clean complete."

# -------------------------------------------------------------------
# Phony Targets
# -------------------------------------------------------------------

.PHONY: all compile_src compile_tbs run_all run clean
