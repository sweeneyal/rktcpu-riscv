# RKTCPU - RISC V

[![VHDL Testbenches](https://github.com/sweeneyal/scrv/actions/workflows/scrv_tests.yml/badge.svg)](https://github.com/sweeneyal/rktcpu-riscv/actions/workflows/scrv_tests.yml)

![alttext](docs/rktcpu_riscv.png)

RktCpu is yet another soft-core RISC-V processor based on the latest rv32ia standard. The goal of this project is to build a processor targeting Xilinx products allowing me to use it in all sorts of future projects. 

## Road to v1.0.0
- [ ] Investigate adding AXI4Lite to the design.
- [x] Add basic block rams for instruction memory and data memory.
- [ ] Verify on hardware with a blink-led program.
- [ ] Add a debugger bus and debugger.
- [ ] Build a CMake toolset to use for compiling programs for this platform.