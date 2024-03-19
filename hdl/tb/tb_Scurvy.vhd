library vunit_lib;
    context vunit_lib.vunit_context;

entity tb_Scurvy is
    generic (runner_cfg : string);
end entity tb_Scurvy;

architecture tb of tb_Scurvy is
begin
    
    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_basic_loop") then
                assert false report "Not implemented";
            elsif run("t_basic_mul") then
                assert false report "Not implemented";
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;