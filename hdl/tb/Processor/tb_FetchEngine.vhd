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

entity tb_FetchEngine is
    generic (runner_cfg : string);
end entity tb_FetchEngine;

architecture rtl of tb_FetchEngine is
    signal clk       : std_logic := '0';
    signal resetn    : std_logic := '0';
    signal pc        : std_logic_vector(31 downto 0) := x"00000000";
    signal iren      : std_logic := '0';
    signal ivalid    : std_logic := '0';
    signal stall     : std_logic := '0';
    signal rpc       : std_logic_vector(31 downto 0) := x"00000000";
    signal pcwen     : std_logic := '0';
    signal pcu       : std_logic_vector(31 downto 0) := x"00000000";
    signal ext_stall : std_logic := '0';
    signal data      : std_logic_vector(31 downto 0) := x"00000000";
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : entity rktcpu.FetchEngine
    port map (
        i_clk    => clk,
        i_resetn => resetn,

        o_pc     => pc,
        o_iren   => iren,
        i_stall  => stall,
        o_rpc    => rpc,
        i_ivalid => '1',

        i_pcwen => pcwen,
        i_pc    => pcu
    );

    SimulatedRamRead: process(clk)
    begin
        if rising_edge(clk) then
            if (resetn = '0') then
                ivalid <= '0';
            else
                ivalid <= iren and not ext_stall;
                data   <= pc;
            end if;
        end if;
    end process SimulatedRamRead;

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
            elsif run("t_randompc") then
                resetn <= '0';
                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';
                for ii in 1 to 400 loop
                    wait until rising_edge(clk);

                    pcwen <= '0';
                    if ((ii mod 7) = 0) then
                        pcwen <= '1';
                        pcu   <= x"00000000";
                    end if;
                end loop;
            elsif run("t_randomstall") then
                resetn <= '0';
                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';
                for ii in 1 to 400 loop
                    wait until rising_edge(clk);

                    stall <= '0';
                    if ((ii mod 7) = 0) then
                        stall <= '1';
                    end if;
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture rtl;