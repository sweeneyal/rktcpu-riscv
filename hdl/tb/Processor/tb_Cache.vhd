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

entity tb_Cache is
    generic (
        runner_cfg : string
    );
end entity tb_Cache;

architecture tb of tb_Cache is
    signal clk_i      : std_logic;
    signal resetn_i   : std_logic;
    signal ctrl_alu_i : alu_controls_t;
    signal en_i       : std_logic;
    signal opA_i      : std_logic_vector(31 downto 0);
    signal opB_i      : std_logic_vector(31 downto 0);
    signal res_o      : std_logic_vector(31 downto 0);
begin
    
    CreateClock(clk=>clk_i, period=>5 ns);

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_simple") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;