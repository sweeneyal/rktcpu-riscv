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

library scrv;
    use scrv.RiscVDefinitions.all;
    use scrv.ControlEntities.all;
    use scrv.DataPathEntities.all;

library tb;
    use tb.UvmTbPeripherals.all;

entity tb_WhiteBox is
    generic (runner_cfg : string);
end entity tb_WhiteBox;

architecture tb of tb_WhiteBox is
    -- System level signals
    signal i_clk    : std_logic;
    signal i_resetn : std_logic;

    -- Bus Signals
    signal instr_addr   : std_logic_vector(31 downto 0) := (others => '0');
    signal instr_ren    : std_logic := '0';
    signal instr_wen    : std_logic_vector(3 downto 0) := (others => '0');
    signal instr_wdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal instr_rdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal instr_rvalid : std_logic := '0';

    -- Bus Signals
    signal data_addr   : std_logic_vector(31 downto 0);
    signal data_ren    : std_logic;
    signal data_wen    : std_logic_vector(3 downto 0);
    signal data_wdata  : std_logic_vector(31 downto 0);
    signal data_rdata  : std_logic_vector(31 downto 0);
    signal data_rvalid : std_logic;

    -- Datapath Signals
    signal dpath_pc     : std_logic_vector(31 downto 0) := (others => '0');
    signal dpath_opcode : std_logic_vector(6 downto 0) := (others => '0');
    signal dpath_rs1    : std_logic_vector(4 downto 0) := (others => '0');
    signal dpath_rs2    : std_logic_vector(4 downto 0) := (others => '0');
    signal dpath_rd     : std_logic_vector(4 downto 0) := (others => '0');
    signal dpath_funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal dpath_funct7 : std_logic_vector(6 downto 0) := (others => '0');
    signal dpath_itype  : std_logic_vector(11 downto 0) := (others => '0');
    signal dpath_stype  : std_logic_vector(11 downto 0) := (others => '0');
    signal dpath_btype  : std_logic_vector(12 downto 0) := (others => '0');
    signal dpath_utype  : std_logic_vector(19 downto 0) := (others => '0');
    signal dpath_jtype  : std_logic_vector(20 downto 0) := (others => '0');
    signal dpath_done  : std_logic := '0';
    signal dpath_jtaken: std_logic := '0';
    signal dpath_btaken: std_logic := '0';
    signal dpath_nxtpc : std_logic_vector(31 downto 0) := (others => '0');

    -- Debug signals for datapath
    signal result     : std_logic_vector(31 downto 0);
    signal valid      : std_logic;

    -- Gold signals
    signal gold_data_addr   : std_logic_vector(31 downto 0);
    signal gold_data_ren    : std_logic;
    signal gold_data_wen    : std_logic_vector(3 downto 0);
    signal gold_data_wdata  : std_logic_vector(31 downto 0);

    signal gold_dpath_done  : std_logic := '0';
    signal gold_dpath_jtaken: std_logic := '0';
    signal gold_dpath_btaken: std_logic := '0';
    signal gold_dpath_nxtpc : std_logic_vector(31 downto 0) := (others => '0');
    signal gold_dbg_result  : std_logic_vector(31 downto 0);
    signal gold_dbg_valid   : std_logic;
begin
    
    CreateClock(clk=>i_clk, period=>5 ns);

    eControlDut : ControlEngine
    port map (
        -- System level signals
        i_clk    => i_clk,
        i_resetn => i_resetn,

        -- Bus Signals
        o_instr_addr   => instr_addr,
        o_instr_ren    => instr_ren,
        o_instr_wen    => instr_wen,
        o_instr_wdata  => instr_wdata,
        i_instr_rdata  => instr_rdata,
        i_instr_rvalid => instr_rvalid,

        -- Datapath Signals
        o_dpath_pc     => dpath_pc,
        o_dpath_opcode => dpath_opcode,
        o_dpath_rs1    => dpath_rs1,
        o_dpath_rs2    => dpath_rs2,
        o_dpath_rd     => dpath_rd,
        o_dpath_funct3 => dpath_funct3,
        o_dpath_funct7 => dpath_funct7,
        o_dpath_itype  => dpath_itype,
        o_dpath_stype  => dpath_stype,
        o_dpath_btype  => dpath_btype,
        o_dpath_utype  => dpath_utype,
        o_dpath_jtype  => dpath_jtype,
        i_dpath_done   => dpath_done,
        i_dpath_jtaken => dpath_jtaken,
        i_dpath_btaken => dpath_btaken,
        i_dpath_nxtpc  => dpath_nxtpc
    );

    eIMem : InstructionMemory
    port map (
        i_clk          => i_clk,
        i_resetn       => i_resetn,
        i_instr_addr   => instr_addr,
        i_instr_ren    => instr_ren,
        i_instr_wen    => instr_wen,
        i_instr_wdata  => instr_wdata,
        o_instr_rdata  => instr_rdata,
        o_instr_rvalid => instr_rvalid
    );

    eDataDut : DataPath
    port map (
        -- System level signals
        i_clk    => i_clk,
        i_resetn => i_resetn,

        -- Bus Signals
        o_data_addr   => data_addr,
        o_data_ren    => data_ren,
        o_data_wen    => data_wen,
        o_data_wdata  => data_wdata,
        i_data_rdata  => data_rdata,
        i_data_rvalid => data_rvalid,

        -- Datapath Signals
        i_dpath_pc     => dpath_pc,
        i_dpath_opcode => dpath_opcode,
        i_dpath_rs1    => dpath_rs1,
        i_dpath_rs2    => dpath_rs2,
        i_dpath_rd     => dpath_rd,
        i_dpath_funct3 => dpath_funct3,
        i_dpath_funct7 => dpath_funct7,
        i_dpath_itype  => dpath_itype,
        i_dpath_stype  => dpath_stype,
        i_dpath_btype  => dpath_btype,
        i_dpath_utype  => dpath_utype,
        i_dpath_jtype  => dpath_jtype,
        o_dpath_done   => dpath_done,
        o_dpath_jtaken => dpath_jtaken,
        o_dpath_btaken => dpath_btaken,
        o_dpath_nxtpc  => dpath_nxtpc,

        o_dbg_result => result,
        o_dbg_valid  => valid
    );

    eRam : RandomRam
    generic map (
        cCheckUninitialized => false
    ) port map (
        i_clk         => i_clk,
        i_resetn      => i_resetn,
        i_data_addr   => data_addr,
        i_data_ren    => data_ren,
        i_data_wen    => data_wen,
        i_data_wdata  => data_wdata,
        o_data_rdata  => data_rdata,
        o_data_rvalid => data_rvalid
    );

    eSimulatedDpath : SimulatedDataPath
    port map (
        -- System level signals
        i_clk    => i_clk,
        i_resetn => i_resetn,

        -- Bus Signals
        o_data_addr   => gold_data_addr,
        o_data_ren    => gold_data_ren,
        o_data_wen    => gold_data_wen,
        o_data_wdata  => gold_data_wdata,
        i_data_rdata  => data_rdata,
        i_data_rvalid => data_rvalid,

        -- Datapath Signals
        i_dpath_pc     => dpath_pc,
        i_dpath_opcode => dpath_opcode,
        i_dpath_rs1    => dpath_rs1,
        i_dpath_rs2    => dpath_rs2,
        i_dpath_rd     => dpath_rd,
        i_dpath_funct3 => dpath_funct3,
        i_dpath_funct7 => dpath_funct7,
        i_dpath_itype  => dpath_itype,
        i_dpath_stype  => dpath_stype,
        i_dpath_btype  => dpath_btype,
        i_dpath_utype  => dpath_utype,
        i_dpath_jtype  => dpath_jtype,
        o_dpath_done   => gold_dpath_done,
        o_dpath_jtaken => gold_dpath_jtaken,
        o_dpath_btaken => gold_dpath_btaken,
        o_dpath_nxtpc  => gold_dpath_nxtpc,

        o_dbg_result => gold_dbg_result,
        o_dbg_valid => gold_dbg_valid
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            -- Need to add verification to the address reading.
            if run("t_whitebox") then
                --check(false);
                i_resetn <= '0';
                wait until rising_edge(i_clk);
                wait for 100 ps;
                i_resetn <= '1';
                wait for 1000 ns;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;

    ResultChecker: process(gold_dbg_result, gold_dbg_valid, result, valid)
    begin
        if (valid = '1') then
            --assert(gold_dbg_valid = '1') report "Instruction failed, incorrect valid response. Opcode = " & to_hstring(dpath_opcode) & " Valid = " & std_logic'image(gold_dbg_valid);
            --assert(gold_dbg_result = result) report "Instruction failed, incorrect result from datapath.";
        end if;
    end process ResultChecker;
    
end architecture tb;