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

## Progress so far
I've created several first iterations of elements of the data path and control units, and have created tests for each. Not all of them pass, primarily because the ones that don't pass are stand-ins for making further tests. It's like the adage goes, "if you have 100% passing tests, you need to add more tests."

Currently, I'm working on integration tests for some of these components so that I can verify that they work well together, with no unnecessary stalls or errant flags, etc. Once I have these tests completed and all components verified to some extent, the plan is to build DUT harnesses around the Datapath and Control and test on hardware, verifying that the parts meet timing.

Speaking of timing, I'm particularly scared that the ALU and Branch Unit will not meet timing, since the critical path for those is Registers -> ALU/Branch Unit -> Registers in under 5 to 10 ns. That seems pretty unfeasible, so I may insert registers at the entry point of the ALU, which means ALU operations will take an additional clock cycle but meet timing.

A goal of this would be to make it fully pipelined, but I'd rather have a functioning implementation that's slow than a broken implementation that's fast.