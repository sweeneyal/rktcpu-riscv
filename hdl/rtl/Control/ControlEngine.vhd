library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library scrv;
    use scrv.ControlEntities.all;

entity ControlEngine is
    port (
        -- System level signals
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- Bus Signals
        o_instr_addr   : out std_logic_vector(31 downto 0);
        o_instr_ren    : out std_logic;
        o_instr_wen    : out std_logic_vector(3 downto 0);
        o_instr_wdata  : out std_logic_vector(31 downto 0);
        i_instr_rdata  : in std_logic_vector(31 downto 0);
        i_instr_rvalid : in std_logic;

        -- Datapath Signals
        o_dpath_pc     : out std_logic_vector(31 downto 0);
        o_dpath_opcode : out std_logic_vector(6 downto 0);
        o_dpath_rs1    : out std_logic_vector(4 downto 0);
        o_dpath_rs2    : out std_logic_vector(4 downto 0);
        o_dpath_rd     : out std_logic_vector(4 downto 0);
        o_dpath_funct3 : out std_logic_vector(2 downto 0);
        o_dpath_funct7 : out std_logic_vector(6 downto 0);
        o_dpath_itype  : out std_logic_vector(11 downto 0);
        o_dpath_stype  : out std_logic_vector(11 downto 0);
        o_dpath_btype  : out std_logic_vector(12 downto 0);
        o_dpath_utype  : out std_logic_vector(19 downto 0);
        o_dpath_jtype  : out std_logic_vector(20 downto 0);
        i_dpath_done   : in std_logic;
        i_dpath_jtaken : in std_logic;
        i_dpath_btaken : in std_logic;
        i_dpath_nxtpc  : in std_logic_vector(31 downto 0)
    );
end entity ControlEngine;

architecture rtl of ControlEngine is
    signal pcwen  : std_logic;
    signal exren  : std_logic;
    signal instr  : std_logic_vector(31 downto 0);
    signal ivalid : std_logic;
begin
    
    eFetchEngine : FetchEngine
    port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,
        i_pc     => i_dpath_nxtpc,
        i_pcwen  => pcwen,
        o_pc     => o_instr_addr,
        o_pcren  => o_instr_ren,
        i_instr  => i_instr_rdata,
        i_ivalid => i_instr_rvalid,
        i_ren    => exren,
        o_instr  => instr,
        o_ivalid => ivalid,
        o_empty  => open,
        o_full   => open
    );

    eExecuteEngine : ExecuteEngine
    port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,
        o_ren    => exren,
        i_instr  => instr,
        i_ivalid => ivalid,

        o_pc     => o_dpath_pc,
        o_pcwen  => pcwen,
        o_opcode => o_dpath_opcode,
        o_rs1    => o_dpath_rs1,
        o_rs2    => o_dpath_rs2,
        o_rd     => o_dpath_rd,
        o_funct3 => o_dpath_funct3,
        o_funct7 => o_dpath_funct7,
        o_itype  => o_dpath_itype,
        o_stype  => o_dpath_stype,
        o_btype  => o_dpath_btype,
        o_utype  => o_dpath_utype,
        o_jtype  => o_dpath_jtype,

        i_done   => i_dpath_done,
        i_jtaken => i_dpath_jtaken,
        i_btaken => i_dpath_btaken,
        i_nxtpc  => i_dpath_nxtpc
    );
    
end architecture rtl;