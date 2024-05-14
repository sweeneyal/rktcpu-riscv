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

entity tb_DataPath is
    generic (runner_cfg : string);
end entity tb_DataPath;

architecture tb of tb_DataPath is
    -- System level signals
    signal i_clk    : std_logic;
    signal i_resetn : std_logic;

    -- Bus Signals
    signal o_data_addr   : std_logic_vector(31 downto 0);
    signal o_data_ren    : std_logic;
    signal o_data_wen    : std_logic_vector(3 downto 0);
    signal o_data_wdata  : std_logic_vector(31 downto 0);
    signal i_data_rdata  : std_logic_vector(31 downto 0);
    signal i_data_rvalid : std_logic;

    -- Datapath Signals
    signal i_dpath_pc     : std_logic_vector(31 downto 0);
    signal i_dpath_opcode : std_logic_vector(6 downto 0);
    signal i_dpath_rs1    : std_logic_vector(4 downto 0);
    signal i_dpath_rs2    : std_logic_vector(4 downto 0);
    signal i_dpath_rd     : std_logic_vector(4 downto 0);
    signal i_dpath_funct3 : std_logic_vector(2 downto 0);
    signal i_dpath_funct7 : std_logic_vector(6 downto 0);
    signal i_dpath_itype  : std_logic_vector(11 downto 0);
    signal i_dpath_stype  : std_logic_vector(11 downto 0);
    signal i_dpath_btype  : std_logic_vector(12 downto 0);
    signal i_dpath_utype  : std_logic_vector(19 downto 0);
    signal i_dpath_jtype  : std_logic_vector(20 downto 0);
    signal o_dpath_done   : std_logic;
    signal o_dpath_jtaken : std_logic;
    signal o_dpath_btaken : std_logic;
    signal o_dpath_nxtpc  : std_logic_vector(31 downto 0);
begin
    
    CreateClock(clk=>i_clk, period=>5 ns);

    eDut : entity rktcpu.DataPath
    port map (
        -- System level signals
        i_clk    => i_clk,
        i_resetn => i_resetn,

        -- Bus Signals
        o_data_addr   => o_data_addr,
        o_data_ren    => o_data_ren,
        o_data_wen    => o_data_wen,
        o_data_wdata  => o_data_wdata,
        i_data_rdata  => i_data_rdata,
        i_data_rvalid => i_data_rvalid,

        -- Datapath Signals
        i_dpath_pc     => i_dpath_pc,
        i_dpath_opcode => i_dpath_opcode,
        i_dpath_rs1    => i_dpath_rs1,
        i_dpath_rs2    => i_dpath_rs2,
        i_dpath_rd     => i_dpath_rd,
        i_dpath_funct3 => i_dpath_funct3,
        i_dpath_funct7 => i_dpath_funct7,
        i_dpath_itype  => i_dpath_itype,
        i_dpath_stype  => i_dpath_stype,
        i_dpath_btype  => i_dpath_btype,
        i_dpath_utype  => i_dpath_utype,
        i_dpath_jtype  => i_dpath_jtype,
        o_dpath_done   => o_dpath_done,
        o_dpath_jtaken => o_dpath_jtaken,
        o_dpath_btaken => o_dpath_btaken,
        o_dpath_nxtpc  => o_dpath_nxtpc,

        o_dbg_result => open,
        o_dbg_valid => open
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            -- Need to add verification to the address reading.
            if run("t_data_path") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;