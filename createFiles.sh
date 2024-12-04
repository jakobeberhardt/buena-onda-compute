#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the root directory
ROOT_DIR="."

# List of directories to create
DIRS=(
    "$ROOT_DIR/src/cpu/pipeline/BranchPredictor"
    "$ROOT_DIR/src/cpu/alu"
    "$ROOT_DIR/src/cpu/regfile"
    "$ROOT_DIR/src/cpu/control"
    "$ROOT_DIR/src/cpu/bypass"
    "$ROOT_DIR/src/cpu/hazard"
    "$ROOT_DIR/src/cpu/memory"
    "$ROOT_DIR/src/cpu/cache"
    "$ROOT_DIR/src/cpu/tlb"
    "$ROOT_DIR/src/cpu/exceptions"
    "$ROOT_DIR/src/cpu/virtual_memory"
    "$ROOT_DIR/src/cpu/utils"
    "$ROOT_DIR/src/interfaces"
    "$ROOT_DIR/src/peripherals"
    "$ROOT_DIR/testbench/tb_pipeline"
    "$ROOT_DIR/testbench/tests"
    "$ROOT_DIR/scripts"
    "$ROOT_DIR/docs"
    "$ROOT_DIR/simulations/waveforms"
    "$ROOT_DIR/simulations/logs"
)

# Create all directories
for DIR in "${DIRS[@]}"; do
    mkdir -p "$DIR"
done

echo "Directories created successfully."

# List of files to create with their respective paths
FILES=(
    # src/cpu/
    "$ROOT_DIR/src/cpu/RISCVCPU.v"
    
    # src/cpu/pipeline/
    "$ROOT_DIR/src/cpu/pipeline/IF.v"
    "$ROOT_DIR/src/cpu/pipeline/ID.v"
    "$ROOT_DIR/src/cpu/pipeline/EX.v"
    "$ROOT_DIR/src/cpu/pipeline/MEM.v"
    "$ROOT_DIR/src/cpu/pipeline/WB.v"
    "$ROOT_DIR/src/cpu/pipeline/PipelineRegs.v"
    "$ROOT_DIR/src/cpu/pipeline/PipelineControl.v"
    
    # src/cpu/pipeline/BranchPredictor/
    "$ROOT_DIR/src/cpu/pipeline/BranchPredictor/BranchPredictor.v"
    "$ROOT_DIR/src/cpu/pipeline/BranchPredictor/BTB.v"
    "$ROOT_DIR/src/cpu/pipeline/BranchPredictor/PredictorFSM.v"
    
    # src/cpu/alu/
    "$ROOT_DIR/src/cpu/alu/ALU.v"
    
    # src/cpu/regfile/
    "$ROOT_DIR/src/cpu/regfile/RegFile.v"
    
    # src/cpu/control/
    "$ROOT_DIR/src/cpu/control/ControlUnit.v"
    "$ROOT_DIR/src/cpu/control/Decoder.v"
    
    # src/cpu/bypass/
    "$ROOT_DIR/src/cpu/bypass/BypassUnit.v"
    
    # src/cpu/hazard/
    "$ROOT_DIR/src/cpu/hazard/HazardUnit.v"
    
    # src/cpu/memory/
    "$ROOT_DIR/src/cpu/memory/IMemory.v"
    "$ROOT_DIR/src/cpu/memory/DMemory.v"
    
    # src/cpu/cache/
    "$ROOT_DIR/src/cpu/cache/ICache.v"
    "$ROOT_DIR/src/cpu/cache/DCache.v"
    
    # src/cpu/tlb/
    "$ROOT_DIR/src/cpu/tlb/ITLB.v"
    "$ROOT_DIR/src/cpu/tlb/DTLB.v"
    
    # src/cpu/exceptions/
    "$ROOT_DIR/src/cpu/exceptions/ExceptionHandler.v"
    
    # src/cpu/virtual_memory/
    "$ROOT_DIR/src/cpu/virtual_memory/VirtualMemory.v"
    
    # src/cpu/utils/
    "$ROOT_DIR/src/cpu/utils/Constants.v"
    "$ROOT_DIR/src/cpu/utils/Opcodes.v"
    
    # src/interfaces/
    "$ROOT_DIR/src/interfaces/MemoryInterface.v"
    "$ROOT_DIR/src/interfaces/CacheInterface.v"
    
    # src/peripherals/
    "$ROOT_DIR/src/peripherals/UART.v"
    "$ROOT_DIR/src/peripherals/DMA.v"
    
    # testbench/
    "$ROOT_DIR/testbench/tb_riscv_cpu.v"
    
    # testbench/tb_pipeline/
    "$ROOT_DIR/testbench/tb_pipeline/tb_fetch_stage.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_decode_stage.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_execute_stage.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_memory_stage.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_writeback_stage.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_pipeline_registers.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_hazard_detection.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_forwarding_unit.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_branch_predictor.v"
    "$ROOT_DIR/testbench/tb_pipeline/tb_branch_target_buffer.v"
    
    # Additional testbench files
    "$ROOT_DIR/testbench/tb_alu.v"
    "$ROOT_DIR/testbench/tb_register_file.v"
    "$ROOT_DIR/testbench/tb_cache.v"
    "$ROOT_DIR/testbench/tb_tlb.v"
    "$ROOT_DIR/testbench/tb_virtual_memory.v"
    
    # testbench/tests/
    "$ROOT_DIR/testbench/tests/buffer_sum_test.v"
    "$ROOT_DIR/testbench/tests/mem_copy_test.v"
    "$ROOT_DIR/testbench/tests/matrix_multiply_test.v"
    
    # scripts/
    "$ROOT_DIR/scripts/compile.sh"
    "$ROOT_DIR/scripts/run_tests.sh"
    
    # docs/
    "$ROOT_DIR/docs/architecture.md"
    "$ROOT_DIR/docs/module_descriptions.md"
    
    # Makefile and README
    "$ROOT_DIR/Makefile"
    "$ROOT_DIR/README.md"
)

# Create all files
for FILE in "${FILES[@]}"; do
    # Create empty file if it doesn't exist
    if [ ! -f "$FILE" ]; then
        touch "$FILE"
    fi
done

echo "Files created successfully."

# Optional: Add executable permissions to scripts
chmod +x "$ROOT_DIR/scripts/compile.sh"
chmod +x "$ROOT_DIR/scripts/run_tests.sh"

echo "Setup completed successfully."
