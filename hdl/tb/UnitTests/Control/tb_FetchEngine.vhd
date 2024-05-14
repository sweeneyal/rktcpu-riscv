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
    use rktcpu.RiscVDefinitions.all;

entity tb_FetchEngine is
    generic (runner_cfg : string);
end entity tb_FetchEngine;

architecture tb of tb_FetchEngine is
    signal clk      : std_logic;
    signal resetn   : std_logic;
    signal pc_i     : std_logic_vector(31 downto 0);
    signal pcwen    : std_logic;
    signal pc_o     : std_logic_vector(31 downto 0);
    signal pcren    : std_logic;
    signal instr_i  : std_logic_vector(31 downto 0);
    signal ivalid_i : std_logic;
    signal ren      : std_logic;
    signal instr_o  : std_logic_vector(31 downto 0);
    signal ivalid_o : std_logic;
    signal empty    : std_logic;
    signal full     : std_logic;
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : entity rktcpu.FetchEngine
    port map (
        i_clk    => clk,
        i_resetn => resetn,
        i_pc     => pc_i,
        i_pcwen  => pcwen,
        o_pc     => pc_o,
        o_pcren  => pcren,
        i_instr  => instr_i,
        i_ivalid => ivalid_i,
        i_ren    => ren,
        o_instr  => instr_o,
        o_ivalid => ivalid_o,
        o_empty  => empty,
        o_full   => full
    );

    Stimuli: process
        variable RandData : RandomPType;
        variable history  : std_logic_matrix_t(0 to 20)(31 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_single_instr") then
                resetn   <= '0';
                pc_i     <= (others => '0');
                pcwen    <= '0';
                instr_i  <= RandData.RandSlv(x"00000000", x"FFFFFFFF");
                ivalid_i <= '0';
                ren      <= '0';
                
                -- Set resetn
                wait until rising_edge(clk);
                wait for 100 ps;
                check(empty    = '1');
                check(full     = '0');
                check(ivalid_o = '0');
                resetn <= '1';

                -- Wait two clock cycles and we see our first request for instruction.
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                wait for 100 ps;
                check(pcren = '1');
                check(pc_o = x"00000000");
                history(0) := instr_i;
                ivalid_i <= '1';
                
                -- We should see a request for a second instruction as well.
                wait until rising_edge(clk);
                wait for 100 ps;
                check(empty = '0');
                check(full  = '0');
                history(1) := RandData.RandSlv(x"00000000", x"FFFFFFFF");
                instr_i <= history(1);
                check(pcren = '1');
                check(pc_o = x"00000004");
                -- Meanwhile, start a read for the first instruction.
                ren <= '1';

                wait until rising_edge(clk);
                wait for 100 ps;
                check(pcren = '1');
                check(pc_o = x"00000008");
                history(2) := RandData.RandSlv(x"00000000", x"FFFFFFFF");
                instr_i <= history(2);
                ivalid_i <= '1';
                check(ivalid_o = '1');
                check(instr_o = history(0));
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;