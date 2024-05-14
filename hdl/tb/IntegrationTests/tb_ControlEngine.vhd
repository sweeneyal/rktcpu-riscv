library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RiscVDefinitions.all;

library tb;
    use tb.UvmTbPeripherals.all;

entity tb_ControlEngine is
    generic (runner_cfg : string);
end entity tb_ControlEngine;

architecture tb of tb_ControlEngine is
    -- System level signals
    signal i_clk    : std_logic;
    signal i_resetn : std_logic;

    -- Bus Signals
    signal o_instr_addr   : std_logic_vector(31 downto 0) := (others => '0');
    signal o_instr_ren    : std_logic := '0';
    signal o_instr_wen    : std_logic_vector(3 downto 0) := (others => '0');
    signal o_instr_wdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal i_instr_rdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal i_instr_rvalid : std_logic := '0';

    -- Datapath Signals
    signal o_dpath_pc     : std_logic_vector(31 downto 0) := (others => '0');
    signal o_dpath_opcode : std_logic_vector(6 downto 0) := (others => '0');
    signal o_dpath_rs1    : std_logic_vector(4 downto 0) := (others => '0');
    signal o_dpath_rs2    : std_logic_vector(4 downto 0) := (others => '0');
    signal o_dpath_rd     : std_logic_vector(4 downto 0) := (others => '0');
    signal o_dpath_funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal o_dpath_funct7 : std_logic_vector(6 downto 0) := (others => '0');
    signal o_dpath_itype  : std_logic_vector(11 downto 0) := (others => '0');
    signal o_dpath_stype  : std_logic_vector(11 downto 0) := (others => '0');
    signal o_dpath_btype  : std_logic_vector(12 downto 0) := (others => '0');
    signal o_dpath_utype  : std_logic_vector(19 downto 0) := (others => '0');
    signal o_dpath_jtype  : std_logic_vector(20 downto 0) := (others => '0');
    signal i_dpath_done   : std_logic := '0';
    signal i_dpath_jtaken : std_logic := '0';
    signal i_dpath_btaken : std_logic := '0';
    signal i_dpath_nxtpc  : std_logic_vector(31 downto 0) := (others => '0');
begin
    
    CreateClock(clk=>i_clk, period=>5 ns);

    eDut : entity rktcpu.ControlEngine
    port map (
        -- System level signals
        i_clk    => i_clk,
        i_resetn => i_resetn,

        -- Bus Signals
        o_instr_addr   => o_instr_addr,
        o_instr_ren    => o_instr_ren,
        o_instr_wen    => o_instr_wen,
        o_instr_wdata  => o_instr_wdata,
        i_instr_rdata  => i_instr_rdata,
        i_instr_rvalid => i_instr_rvalid,

        -- Datapath Signals
        o_dpath_pc     => o_dpath_pc,
        o_dpath_opcode => o_dpath_opcode,
        o_dpath_rs1    => o_dpath_rs1,
        o_dpath_rs2    => o_dpath_rs2,
        o_dpath_rd     => o_dpath_rd,
        o_dpath_funct3 => o_dpath_funct3,
        o_dpath_funct7 => o_dpath_funct7,
        o_dpath_itype  => o_dpath_itype,
        o_dpath_stype  => o_dpath_stype,
        o_dpath_btype  => o_dpath_btype,
        o_dpath_utype  => o_dpath_utype,
        o_dpath_jtype  => o_dpath_jtype,
        i_dpath_done   => i_dpath_done,
        i_dpath_jtaken => i_dpath_jtaken,
        i_dpath_btaken => i_dpath_btaken,
        i_dpath_nxtpc  => i_dpath_nxtpc
    );

    eIMem : InstructionMemory
    port map (
        i_clk          => i_clk,
        i_resetn       => i_resetn,
        i_instr_addr   => o_instr_addr,
        i_instr_ren    => o_instr_ren,
        i_instr_wen    => o_instr_wen,
        i_instr_wdata  => o_instr_wdata,
        o_instr_rdata  => i_instr_rdata,
        o_instr_rvalid => i_instr_rvalid
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            -- Need to add verification to the address reading.
            if run("t_control_engine") then
                --check(false);
                i_resetn <= '0';
                wait until rising_edge(i_clk);
                wait for 100 ps;
                i_resetn <= '1';
                wait for 100 ns;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;