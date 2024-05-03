library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonTypes.all;
    use universal.CommonFunctions.all;

package UvmTbPeripherals is

component RandomRam is
    generic (
        cCheckUninitialized : boolean := false
    );
    port (
        i_clk         : in std_logic;
        i_resetn      : in std_logic;
        i_data_addr   : in std_logic_vector(31 downto 0);
        i_data_ren    : in std_logic;
        i_data_wen    : in std_logic_vector(3 downto 0);
        i_data_wdata  : in std_logic_vector(31 downto 0);
        o_data_rdata  : out std_logic_vector(31 downto 0);
        o_data_rvalid : out std_logic
    );
end component RandomRam;

component SimulatedDataPath is
    port (
        -- System level signals
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- Bus Signals
        o_data_addr   : out std_logic_vector(31 downto 0);
        o_data_ren    : out std_logic;
        o_data_wen    : out std_logic_vector(3 downto 0);
        o_data_wdata  : out std_logic_vector(31 downto 0);
        i_data_rdata  : in std_logic_vector(31 downto 0);
        i_data_rvalid : in std_logic;

        -- Datapath Signals
        i_dpath_pc     : in std_logic_vector(31 downto 0);
        i_dpath_opcode : in std_logic_vector(6 downto 0);
        i_dpath_rs1    : in std_logic_vector(4 downto 0);
        i_dpath_rs2    : in std_logic_vector(4 downto 0);
        i_dpath_rd     : in std_logic_vector(4 downto 0);
        i_dpath_funct3 : in std_logic_vector(2 downto 0);
        i_dpath_funct7 : in std_logic_vector(6 downto 0);
        i_dpath_itype  : in std_logic_vector(11 downto 0);
        i_dpath_stype  : in std_logic_vector(11 downto 0);
        i_dpath_btype  : in std_logic_vector(12 downto 0);
        i_dpath_utype  : in std_logic_vector(19 downto 0);
        i_dpath_jtype  : in std_logic_vector(20 downto 0);
        o_dpath_done   : out std_logic;
        o_dpath_jtaken : out std_logic;
        o_dpath_btaken : out std_logic;
        o_dpath_nxtpc  : out std_logic_vector(31 downto 0)
    );
end component SimulatedDataPath;

component InstructionMemory is
    port (
        i_clk          : in std_logic;
        i_resetn       : in std_logic;
        i_instr_addr   : in std_logic_vector(31 downto 0);
        i_instr_ren    : in std_logic;
        i_instr_wen    : in std_logic_vector(3 downto 0);
        i_instr_wdata  : in std_logic_vector(31 downto 0);
        o_instr_rdata  : out std_logic_vector(31 downto 0);
        o_instr_rvalid : out std_logic
    );
end component InstructionMemory;

end package UvmTbPeripherals;