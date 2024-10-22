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

entity tb_SimpleAllUp is
    generic (
        encoded_tb_cfg : string;
        runner_cfg : string
    );
end entity tb_SimpleAllUp;

architecture tb of tb_SimpleAllUp is
    type tb_cfg_t is record
        instructions : string;
    end record tb_cfg_t;

    impure function decode (enc_tb_cfg : string) return tb_cfg_t is
    begin
        return (instructions=>get(enc_tb_cfg, "instructions"));
    end function;

    constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

    signal clk     : std_logic := '0';
    signal resetn  : std_logic := '0';

    signal instr_addr   : std_logic_vector(31 downto 0) := x"00000000";
    signal instr_ren    : std_logic := '0';
    signal instr_wen    : std_logic_vector(3 downto 0) := "0000";
    signal instr_wdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal instr_wready : std_logic := '0';
    signal instr_rdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal instr_rvalid : std_logic := '0';

    signal data_addr   : std_logic_vector(31 downto 0) := x"00000000";
    signal data_addr_upper : std_logic_vector(18 downto 0) := "0000000000000000000";
    signal data_ren    : std_logic := '0';
    signal data_ren_idxed : std_logic := '0';
    signal data_wen    : std_logic_vector(3 downto 0) := "0000";
    signal data_wdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal data_wready : std_logic := '0';
    signal data_rdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal data_rvalid : std_logic := '0';
    signal data_local_rdata  : std_logic_vector(31 downto 0) := x"00000000";
    signal data_local_rvalid : std_logic := '0';

    signal gpio_ren_idxed : std_logic := '0';
    signal gpio           : std_logic_vector(31 downto 0) := x"00000000";
    signal gpio_rdata     : std_logic_vector(31 downto 0) := x"00000000";
    signal gpio_rvalid    : std_logic := '0';
begin

    CreateClock(clk=>clk, period=>5 ns);
    
    instr_wready <= (instr_wen(3) or instr_wen(2) or instr_wen(1) or instr_wen(0)) and instr_ren;
    data_wready  <= (data_wen(3) or data_wen(2) or data_wen(1) or data_wen(0)) and data_ren;

    eDut : entity rktcpu.RktCpuRiscV
    port map (
        i_clk    => clk,
        i_resetn => resetn,

        -- Add debug ports

        o_instr_addr   => instr_addr,
        o_instr_ren    => instr_ren,
        o_instr_wen    => instr_wen,
        o_instr_wdata  => instr_wdata,
        i_instr_wready => instr_wready,
        i_instr_rdata  => instr_rdata,
        i_instr_rvalid => instr_rvalid,

        o_data_addr   => data_addr,
        o_data_ren    => data_ren,
        o_data_wen    => data_wen,
        o_data_wdata  => data_wdata,
        i_data_wready => data_wready,
        i_data_rdata  => data_rdata,
        i_data_rvalid => data_rvalid,

        i_extirpt => '0',
        i_irpts   => x"0000"
    );

    eImem : entity rktcpu.InstructionRom
    generic map (
        cInstructionHexPath => tb_cfg.instructions,
        cMaxAddress         => 1024
    ) port map (
        i_clk          => clk,
        i_instr_addr   => instr_addr,
        i_instr_ren    => instr_ren,
        i_instr_wen    => "0000",
        i_instr_wdata  => x"00000000",
        o_instr_rdata  => instr_rdata,
        o_instr_rvalid => instr_rvalid
    );

    data_addr_upper <= data_addr(31 downto 13);
    data_ren_idxed <= data_ren and bool2bit(data_addr_upper = "0000000000000000001");

    data_rdata <= gpio_rdata when (data_addr = x"00010000") else data_local_rdata;
    data_rvalid <= gpio_rvalid when (data_addr = x"00010000") else data_local_rvalid;

    eDmem : entity rktcpu.ByteAddrBram
    generic map (
        cAddressWidth_b => 13,
        cMaxAddress     => 1024,
        cWordWidth_B    => 4
    ) port map (
        i_clk => clk,

        i_addra   => data_addr(12 downto 0),
        i_ena     => data_ren_idxed,
        i_wena    => data_wen,
        i_wdataa  => data_wdata,
        o_rdataa  => data_local_rdata,
        o_rvalida => data_local_rvalid,

        i_addrb   => (others => '0'),
        i_enb     => '0',
        i_wenb    => "0000",
        i_wdatab  => (others => '0'),
        o_rdatab  => open,
        o_rvalidb => open
    );

    gpio_ren_idxed <= bool2bit(data_addr = x"00010000");

    eGpio : entity rktcpu.GpioRegister
    port map (
        i_clk    => clk,
        i_resetn => resetn,
        i_ren    => gpio_ren_idxed,
        i_wen    => data_wen,
        i_wdata  => data_wdata,
        o_rdata  => gpio_rdata,
        o_gpio   => gpio
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

    Checkers: process(instr_addr, instr_wen, instr_wdata)
    begin
        --report to_hstring(i_instr_addr);
        check(instr_addr(1) /= '1' and instr_addr(0) /= '1');
        --report to_hstring(i_instr_wen);
        check(instr_wen(3) /= '1' 
            and instr_wen(2) /= '1' 
            and instr_wen(1) /= '1'
            and instr_wen(0) /= '1');
    end process Checkers;
    
end architecture tb;