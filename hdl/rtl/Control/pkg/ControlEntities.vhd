library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonTypes.all;
    use universal.CommonFunctions.all;

package ControlEntities is

component FetchEngine is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;
        i_pc     : in std_logic_vector(31 downto 0);
        i_pcwen  : in std_logic;
        
        o_pc     : out std_logic_vector(31 downto 0);
        o_pcren  : out std_logic;
        i_instr  : in std_logic_vector(31 downto 0);
        i_ivalid : in std_logic;

        i_ren    : in std_logic;
        o_instr  : out std_logic_vector(31 downto 0);
        o_ivalid : out std_logic;
        o_empty  : out std_logic;
        o_full   : out std_logic
    );
end component FetchEngine;

component ControlEngine is
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
end component ControlEngine;

component ExecuteEngine is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        o_ren    : out std_logic;
        i_instr  : out std_logic_vector(31 downto 0);
        i_ivalid : out std_logic;
        
        o_pcwen  : out std_logic;
        o_pc     : out std_logic_vector(31 downto 0);
        o_opcode : out std_logic_vector(6 downto 0);
        o_rs1    : out std_logic_vector(4 downto 0);
        o_rs2    : out std_logic_vector(4 downto 0);
        o_rd     : out std_logic_vector(4 downto 0);
        o_funct3 : out std_logic_vector(2 downto 0);
        o_funct7 : out std_logic_vector(6 downto 0);
        o_itype  : out std_logic_vector(11 downto 0);
        o_stype  : out std_logic_vector(11 downto 0);
        o_btype  : out std_logic_vector(12 downto 0);
        o_utype  : out std_logic_vector(19 downto 0);
        o_jtype  : out std_logic_vector(20 downto 0);

        i_done   : in std_logic;
        i_jtaken : in std_logic;
        i_btaken : in std_logic;
        i_nxtpc  : in std_logic_vector(31 downto 0)
    );
end component ExecuteEngine;

component SimpleFifo is
    generic (
        cAddressWidth : natural;
        cDataWidth    : natural
    );
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        o_empty  : out std_logic;
        o_aempty : out std_logic;
        o_afull  : out std_logic;
        o_full   : out std_logic;
        
        i_data   : in std_logic_vector(cDataWidth - 1 downto 0);
        i_dvalid : in std_logic;

        i_pop    : in std_logic;
        o_data   : out std_logic_vector(cDataWidth - 1 downto 0);
        o_dvalid : out std_logic
    );
end component SimpleFifo;

component ZiCsr is
    port (
        i_clk     : in std_logic;
        i_resetn  : in std_logic;
        i_opcode  : in std_logic_vector(6 downto 0);
        i_funct3  : in std_logic_vector(2 downto 0);
        i_csraddr : in std_logic_vector(11 downto 0);
        i_rd      : in std_logic_vector(4 downto 0);
        i_rs1     : in std_logic_vector(4 downto 0);
        i_opA     : in std_logic_vector(31 downto 0);
        o_csrr    : out std_logic_vector(31 downto 0);
        o_csrren  : out std_logic;
        o_csrdone : out std_logic;
        i_instret : in std_logic
    );
end component ZiCsr;

component DualPortBram is
    generic (
        cAddressWidth : natural := 30;
        cMaxAddress   : natural := 4096;
        cDataWidth    : natural := 32
    );
    port (
        i_clk : in std_logic;

        i_addra  : in std_logic_vector(cAddressWidth - 1 downto 0);
        i_ena    : in std_logic;
        i_wena   : in std_logic;
        i_wdataa : in std_logic_vector(cDataWidth - 1 downto 0);
        o_rdataa : out std_logic_vector(cDataWidth - 1 downto 0);

        i_addrb  : in std_logic_vector(cAddressWidth - 1 downto 0);
        i_enb    : in std_logic;
        i_wenb   : in std_logic;
        i_wdatab : in std_logic_vector(cDataWidth - 1 downto 0);
        o_rdatab : out std_logic_vector(cDataWidth - 1 downto 0)
    );
end component DualPortBram;

end package ControlEntities;