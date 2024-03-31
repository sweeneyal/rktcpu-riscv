library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilityPkg.all;

entity tb_DspMultiplier is
    generic (runner_cfg : string);
end entity tb_DspMultiplier;

architecture tb of tb_DspMultiplier is
    signal clk     : std_logic;
    signal en      : std_logic;
    signal opA     : std_logic_vector(31 downto 0);
    signal opB     : std_logic_vector(31 downto 0);
    signal funct3  : std_logic_vector(2 downto 0);
    signal mresult : std_logic_vector(31 downto 0);
    signal mdone   : std_logic;
begin
    
    CreateClock(clock=>clk, period=>5 ns);

    eDut : DspMultiplier
    port map (
        i_clk    => clk,
        i_en     => en,
        i_opA    => opA,
        i_opB    => opB,
        i_funct3 => funct3,
        o_result => mresult,
        o_done   => mdone
    );

    Stimuli: process
        variable funct3s : std_logic_matrix_t(0 to 3)(2 downto 0);
        variable result  : std_logic_vector(31 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_standard_mult") then
                funct3s := (cMulFunct3, cMulhFunct3, cMulhsuFunct3, cMulhuFunct3);
                opA <= rand_slv(32);
                opB <= rand_slv(32);
                for ii in 0 to 3 loop
                    funct3 <= funct3s(ii);
                    en     <= '1';
                    for ii in 0 to 3 loop
                        wait until rising_edge(clk);
                        wait for 100 ps;
                    end loop;

                    check(mdone = '1');
                    case funct3 is
                        when cMulFunct3 =>
                            result := shape(resize(signed(opA), 64) * resize(signed(i_opB), 64), 31, 0);
                            check(result = mresult);

                        when cMulhFunct3 =>
                            result := shape(resize(signed(opA), 64) * resize(signed(i_opB), 64), 63, 32);
                            check(result = mresult);
                        
                        when cMulhsuFunct3 =>
                            result := shape(resize(signed(opA), 64) * resize(signed(i_opB), 64), 63, 32);
                            check(result = mresult);

                        when cMulhuFunct3 =>
                            result := shape(resize(signed(opA), 64) * resize(signed(i_opB), 64), 63, 32);
                            check(result = mresult);

                        when others =>
                            result := shape(resize(signed(opA), 64) * resize(signed(i_opB), 64), 63, 32);
                            check(result = mresult);
                            -- Honestly, this should not be an option.
                    
                    end case;

                    en <= '0';
                    wait until rising_edge(clk);
                    wait for 100 ps;
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;