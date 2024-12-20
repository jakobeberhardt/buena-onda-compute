# Buena Onda Compute
sudo apt-get install gtkwave iverilog

## ISA Reference
https://dmytrish.net/lib/riscv/index.html

## Instruction Decoder
https://luplab.gitlab.io/rvcodecjs/

## Installing Modelsim

- Run these commands to get the 32 bit librarys:
    - sudo dpkg --add-architecture i386
    - sudo apt-get update
    - sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 lib32ncurses6 libxft2 libxft2:i386 libxext6 libxext6:i386

- Download the ModelSim - Intel FPGA edition installer (both packages) from the Intel homepage.(https://download.altera.com/akdlm/software/acdsinst/20.1std.1/720/ib_installers/ModelSimSetup-20.1.1.720-linux.run)

- Make the installer executable and run it: 
    - chmod +x ModelSimSetup-20.1.1.720-linux.run
    - ./ModelSimSetup-20.1.1.720-linux.run

- Export the path: can add to .bashrc
    - export PATH=$PATH:/path_to_model_sim/modelsim_ase/bin

- How to run on command line:
    - see make file



## TODO
- Make exhaustive test cases
- Test branch Instructions
- Handle latency if branch depends on load
- Look into why memwwb gives x in some special cases
- Complete and test full ISA
- Store buffer
- Cache
- Virtual Memory 
- Rob
- Branch Predictor
- OoO


