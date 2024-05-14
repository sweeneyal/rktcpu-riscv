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

entity tb_MExtensionUnit is
    generic (runner_cfg : string);
end entity tb_MExtensionUnit;

architecture tb of tb_MExtensionUnit is
    signal clk    : std_logic;
    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal funct7 : std_logic_vector(6 downto 0);
    signal opA    : std_logic_vector(31 downto 0);
    signal opB    : std_logic_vector(31 downto 0);
    signal result : std_logic_vector(31 downto 0);
    signal done   : std_logic;
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eMExtension : entity rktcpu.MExtensionUnit
    port map (
        i_clk    => clk,
        i_opcode => opcode,
        i_funct3 => funct3,
        i_funct7 => funct7,
        i_opA    => opA,
        i_opB    => opB,
        o_result => result,
        o_done   => done
    );

    Stimuli: process
        variable expected : std_logic_vector(31 downto 0);
        variable div : std_logic_vector(31 downto 0);
        variable RandData : RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_mext") then
                funct7   <= "0000001";
                opA      <= RandData.RandSlv(x"00000001", x"0FFFFFFF");
                opB      <= RandData.RandSlv(x"00000001", x"0FFFFFFF");
                opcode   <= cMulDivOpcode;
                for ii in 0 to 7 loop
                    funct3 <= to_slv(ii, 3);
                    wait for 100 ps;

                    case funct3 is
                        when "000" =>
                            expected := shape(std_logic_vector(resize(signed(opA), 64) * resize(signed(opB), 64)), 31, 0);
                            for ii in 0 to 4 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
                            check(done   = '1');
                            check(result = expected);

                        when "001" =>
                            expected := shape(std_logic_vector(resize(signed(opA), 64) * resize(signed(opB), 64)), 63, 32);
                            for ii in 0 to 4 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
                            check(done   = '1');
                            check(result = expected);

                        when "010" =>
                            expected := shape(std_logic_vector(resize(signed(opA), 64) * signed(resize(unsigned(opB), 64))), 63, 32);
                            for ii in 0 to 4 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
                            check(done   = '1');
                            check(result = expected);

                        when "011" =>
                            expected := shape(std_logic_vector(resize(unsigned(opA), 64) * resize(unsigned(opB), 64)), 63, 32);
                            for ii in 0 to 4 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
                            check(done   = '1');
                            check(result = expected);

                        when "100" =>
                            expected := std_logic_vector(divide(signed(opA), signed(opB)));
            
                            for ii in 0 to 12 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
            
                            check(done   = '1');
                            check(result = expected);

                        when "101" =>
                            expected := std_logic_vector(divide(unsigned(opA), unsigned(opB)));
                            for ii in 0 to 12 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
            
                            check(done   = '1');
                            check(result = expected);

                        when "110" =>
                            div := std_logic_vector(divide(signed(opA), signed(opB)));
                            
                            if opA(31) /= opB(31) then
                                if opA(31) = '1' then
                                    expected := std_logic_vector(unsigned(opA) - shape(unsigned(-signed(div)) * unsigned(opB), 31, 0));
                                    expected := std_logic_vector(unsigned(-signed(expected)));
                                else
                                    expected := std_logic_vector(unsigned(opA) - shape(unsigned(-signed(div)) * unsigned(opB), 31, 0));
                                end if;
                            else
                                expected := std_logic_vector(unsigned(opA) - shape(unsigned(div) * unsigned(opB), 31, 0));
                            end if;
            
                            for ii in 0 to 12 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
            
                            check(done   = '1');
                            check(result = expected);

                        when "111" =>
                            div := std_logic_vector(divide(unsigned(opA), unsigned(opB)));
                            expected := std_logic_vector(unsigned(opA) - shape(unsigned(div) * unsigned(opB), 31, 0));
                            for ii in 0 to 12 loop
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
            
                            check(done   = '1');
                            check(result = expected);

                        when others =>
                            check(false);
                    end case;
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;