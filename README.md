# RKTCPU - RISC V

[![VHDL Testbenches](https://github.com/sweeneyal/scrv/actions/workflows/scrv_tests.yml/badge.svg)](https://github.com/sweeneyal/rktcpu-riscv/actions/workflows/scrv_tests.yml)

![alttext](docs/rktcpu_riscv.png)

RktCpu is yet another soft-core RISC-V processor based on the latest rv32ia standard. The goal of this project is to build a processor targeting Xilinx products allowing me to use it in all sorts of future projects. 

## TODO
1. Finish implementing a pipelined implementation of RV32I that runs simple assembly programs.
2. Build a data memory model to simulate memory with.
3. Investigate adding a simple bus to the design.
4. Add basic block rams for instruction memory and data memory.
5. Add a debugger bus and debugger.