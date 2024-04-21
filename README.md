# scrv

[![VHDL Testbenches](https://github.com/sweeneyal/scrv/actions/workflows/scrv_tests.yml/badge.svg)](https://github.com/sweeneyal/scrv/actions/workflows/scrv_tests.yml)

Soft-Core RISC-V (SCRV) affectionately referred to as Scurvy is yet another soft-core RISC-V processor based on the latest standard. The goal of this project is to build a processor targeting Xilinx products allowing me to use it in all sorts of future projects. 

The planned milestones are as follows:
- All components have at least one unit test that passes.
- Control engines together pass and do not create stall cycles (top speed of 1 instr/cycle, though of course MUL and DIV instructions will stall, as well as CSR instructions).
- Basic interfaces to generic bus IP (e.g. flash, onboard RAM, and other bus IP).
- Debug IP for control of the CPU during debugging.
- Hello world program created, as well as binary provided.
- Integration on Arty A7 100T
- Co-Processor demonstration in relevant application (possibly as a game console?)
