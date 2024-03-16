# Introduction
There exist several soft core RISC-V implementations in the open-source world, such as Stephen Nolting's neorv32. This is another RISC-V implementation with goals of building a true processor for an FPGA as a solo project. My goals for this project are to learn the architecture, as well as learn the fundamentals of modern processors in a hands-on approach.

# Implementation
Looking at the neorv32, they use a pretty clever two-cycle non-pipelined implementation, and I'd like to emulate that as well. Each instruction will have a time-of-flight of two cycles.

I do want to support a floating point unit, but I'm not certain how best to implement that. A floating point unit is complicated in and of itself, and will likely slow down the processor.

https://jborza.com/post/2021-05-11-riscv-linux-syscalls/

-- Wishbone bus
o_wb_addr_d : out std_logic_vector(31 downto 0);
i_wb_data_d : in std_logic_vector(31 downto 0);
o_wb_data_d : out std_logic_vector(31 downto 0);
o_wb_we_d   : out std_logic;
o_wb_sel_d  : out std_logic_vector(31 downto 0);
o_wb_stb_d  : out std_logic;
i_wb_ack_d  : in std_logic;
o_wb_cyc_d  : out std_logic;
o_wb_tagn_d : out std_logic;
i_wb_tagn_d : in std_logic