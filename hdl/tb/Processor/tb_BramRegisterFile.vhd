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

entity tb_BramRegisterFile is
    generic (
        runner_cfg : string
    );
end entity tb_BramRegisterFile;

architecture tb of tb_BramRegisterFile is
    type tb_cfg_t is record
        instructions : string;
    end record tb_cfg_t;

    signal clk    : std_logic := '0';
    signal resetn : std_logic := '0';
    signal rs1    : std_logic_vector(4 downto 0) := "00000";
    signal opA    : std_logic_vector(31 downto 0) := x"00000000";
    signal rs2    : std_logic_vector(4 downto 0) := "00000";
    signal opB    : std_logic_vector(31 downto 0) := x"00000000";
    signal rd     : std_logic_vector(4 downto 0) := "00000";
    signal rdwen  : std_logic := '0';
    signal res    : std_logic_vector(31 downto 0) := x"00000000";
begin

    CreateClock(clk=>clk, period=>5 ns);
    
    eDut : entity rktcpu.BramRegisterFile
    port map (
        i_clk    => clk,
        i_resetn => resetn,

        i_rs1    => rs1,
        o_opA    => opA,
        i_rs2    => rs2,
        o_opB    => opB,

        i_rd     => rd,
        i_rdwen  => rdwen,
        i_res    => res
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
                for ii in 0 to 10 loop
                    rdwen <= '1';
                    res   <= x"00000001";
                    rd    <= to_slv(ii, 5);
                    wait until rising_edge(clk);
                    wait for 100 ps;
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;