library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;
    use osvvm.RandomPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;
    use rktcpu.RiscVDefinitions.all;

library tb;
    use tb.RiscVTbTools.all;

entity tb_RktCpuRiscV is
    generic (
        encoded_tb_cfg : string;
        runner_cfg : string
    );
end entity tb_RktCpuRiscV;

architecture tb of tb_RktCpuRiscV is
    type tb_cfg_t is record
        instructions : string;
        logpath      : string;
    end record tb_cfg_t;

    impure function decode (enc_tb_cfg : string) return tb_cfg_t is
    begin
        return (instructions=>get(enc_tb_cfg, "instructions"), logpath=>get(enc_tb_cfg, "logpath"));
    end function;

    constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

    signal clk     : std_logic := '0';
    signal resetn  : std_logic := '0';

    signal instr_addr   : std_logic_vector(31 downto 0) := x"00000000";
    signal instr_ren    : std_logic := '0';
    signal instr_wen    : std_logic_vector(3 downto 0) := "0000";
    signal instr_wdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal instr_rdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal instr_rvalid : std_logic := '0';

    signal data_addr   : std_logic_vector(31 downto 0) := x"00000000";
    signal data_ren    : std_logic := '0';
    signal data_wen    : std_logic_vector(3 downto 0) := "0000";
    signal data_wdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal data_rdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal data_rvalid : std_logic := '0';
begin

    CreateClock(clk=>clk, period=>5 ns);
    
    eDut : entity rktcpu.RktCpuRiscV
    generic map (
        cGenerateLoggers => true,
        cLoggerPath      => tb_cfg.logpath
    ) port map (
        i_clk    => clk,
        i_resetn => resetn,

        -- Add debug ports

        o_instr_addr   => instr_addr,
        o_instr_ren    => instr_ren,
        o_instr_wen    => instr_wen,
        o_instr_wdata  => instr_wdata,
        i_instr_rdata  => instr_rdata,
        i_instr_rvalid => instr_rvalid,

        o_data_addr   => data_addr,
        o_data_ren    => data_ren,
        o_data_wen    => data_wen,
        o_data_wdata  => data_wdata,
        i_data_rdata  => data_rdata,
        i_data_rvalid => data_rvalid,

        i_extirpt => '0',
        i_irpts   => x"0000"
    );

    eImem : entity tb.InstructionMemory
    generic map (
        cInstructionHexPath => tb_cfg.instructions
    ) port map (
        i_clk          => clk,
        i_resetn       => resetn,
        i_instr_addr   => instr_addr,
        i_instr_ren    => instr_ren,
        i_instr_wen    => "0000",
        i_instr_wdata  => x"00000000",
        o_instr_rdata  => instr_rdata,
        o_instr_rvalid => instr_rvalid
    );

    eDmem : entity tb.RandomRam
    port map (
        i_clk         => clk,
        i_resetn      => resetn,
        i_data_addr   => data_addr,
        i_data_ren    => data_ren,
        i_data_wen    => data_wen,
        i_data_wdata  => data_wdata,
        o_data_rdata  => data_rdata,
        o_data_rvalid => data_rvalid
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_simple") then
                resetn <= '0';
                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';
                for ii in 0 to 400 loop
                    wait until rising_edge(clk);
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;