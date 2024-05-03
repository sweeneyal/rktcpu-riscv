library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonTypes.all;
    use universal.CommonFunctions.all;

package DataPathEntities is

component RegisterFile is
    generic (
        cDataWidth        : natural := 32;
        cAddressWidth     : natural := 5
    );
    port (
        i_clk    : in  std_logic;
        i_resetn : in  std_logic;
        i_rs1    : in  std_logic_vector(cAddressWidth - 1 downto 0);
        i_rs2    : in  std_logic_vector(cAddressWidth - 1 downto 0);
        i_rd     : in  std_logic_vector(cAddressWidth - 1 downto 0);
        i_result : in  std_logic_vector(cDataWidth - 1 downto 0);
        i_wen    : in  std_logic;
        o_opA    : out std_logic_vector(cDataWidth - 1 downto 0);
        o_opB    : out std_logic_vector(cDataWidth - 1 downto 0)
    );
end component RegisterFile;

component Alu is
    port (
        i_opcode : in std_logic_vector(6 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        i_funct7 : in std_logic_vector(6 downto 0);
        i_itype  : in std_logic_vector(11 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        i_shamt  : in std_logic_vector(4 downto 0);

        o_res    : out std_logic_vector(31 downto 0);
        o_valid  : out std_logic
    );
end component Alu;

component DataPath is
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
        o_dpath_nxtpc  : out std_logic_vector(31 downto 0);

        -- Debug verification signals
        o_dbg_result : out std_logic_vector(31 downto 0);
        o_dbg_valid  : out std_logic
    );
end component DataPath;

component MExtensionUnit is
    port (
        i_clk    : in std_logic;
        i_opcode : in std_logic_vector(6 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        i_funct7 : in std_logic_vector(6 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        o_result : out std_logic_vector(31 downto 0);
        o_done   : out std_logic
    );
end component MExtensionUnit;

component GoldschmidtDivisionUnit is
    port (
        i_clk    : in std_logic;
        i_en     : in std_logic;
        i_signed : in std_logic;
        i_num    : in std_logic_vector(31 downto 0);
        i_denom  : in std_logic_vector(31 downto 0);
        o_div    : out std_logic_vector(31 downto 0);
        o_rem    : out std_logic_vector(31 downto 0);
        o_error  : out std_logic;
        o_valid  : out std_logic
    );
end component GoldschmidtDivisionUnit;

component BranchUnit is
    port (
        i_pc     : in std_logic_vector(31 downto 0);
        i_opcode : in std_logic_vector(6 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        i_itype  : in std_logic_vector(11 downto 0);
        i_jtype  : in std_logic_vector(20 downto 0);
        i_btype  : in std_logic_vector(12 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);

        o_nxtpc   : out std_logic_vector(31 downto 0);
        o_pjpc    : out std_logic_vector(31 downto 0);
        o_btaken  : out std_logic;
        o_jtaken  : out std_logic;
        o_done    : out std_logic;
        o_bexcept : out std_logic
    );
end component BranchUnit;

component DspMultiplier is
    port (
        i_clk    : in std_logic;
        i_en     : in std_logic;
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        o_result : out std_logic_vector(31 downto 0);
        o_done   : out std_logic
    );
end component DspMultiplier;

component MemAccessUnit is
    port (
        i_clk    : in std_logic;
        i_opcode : in std_logic_vector(6 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_itype  : in std_logic_vector(11 downto 0);
        i_stype  : in std_logic_vector(11 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        
        o_addr : out std_logic_vector(31 downto 0);
        o_men  : out std_logic;
        o_mwen : out std_logic_vector(3 downto 0);
        i_ack  : in std_logic;

        i_rvalid : in  std_logic;
        i_rdata  : in  std_logic_vector(31 downto 0);

        o_data  : out std_logic_vector(31 downto 0);
        o_ldone : out std_logic;
        o_sdone : out std_logic;
        o_msaln : out std_logic
    );
end component MemAccessUnit;

end package DataPathEntities;