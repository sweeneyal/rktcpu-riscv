library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

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

entity tb_AluCore is
    generic (
        runner_cfg : string
    );
end entity tb_AluCore;

architecture tb of tb_AluCore is
    signal clk_i      : std_logic := '0';
    signal resetn_i   : std_logic := '0';
    signal ctrl_alu_i : alu_controls_t;
    signal en_i       : std_logic := '0';
    signal opA_i      : std_logic_vector(31 downto 0) := x"00000000";
    signal opB_i      : std_logic_vector(31 downto 0) := x"00000000";
    signal res_o      : std_logic_vector(31 downto 0) := x"00000000";
begin
    
    CreateClock(clk=>clk_i, period=>5 ns);

    eDut : entity rktcpu.AluCore
    port map (
        i_clk      => clk_i,
        i_resetn   => resetn_i,
        i_ctrl_alu => ctrl_alu_i,
        i_en       => en_i,
        i_opA      => opA_i,
        i_opB      => opB_i,
        o_res      => res_o
    );

    Stimuli: process
        variable local : std_logic_vector(1 downto 0);
        variable seed1, seed2 : integer := 999;

        impure function rand_slv(len : integer) return std_logic_vector is
            variable r : real;
            variable slv : std_logic_vector(len - 1 downto 0);
        begin
            for i in slv'range loop
              uniform(seed1, seed2, r);
              slv(i) := '1' when r > 0.5 else '0';
            end loop;
            return slv;
        end function;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_simple") then
                resetn_i           <= '0';
                ctrl_alu_i.addn    <= '0';
                ctrl_alu_i.res_sel <= "0000";
                ctrl_alu_i.funct3  <= "000";
                ctrl_alu_i.sright  <= '0';
                ctrl_alu_i.sarith  <= '0';
                ctrl_alu_i.slt     <= '0';
                ctrl_alu_i.sltuns  <= '0';

                wait until rising_edge(clk_i);
                wait for 100 ps;

                -- TODO: Change the iterators to seeds for PRNGs to allow better testing.

                -- Test the adder portion of the ALU
                resetn_i <= '1';
                ctrl_alu_i.res_sel <= "1000";
                en_i <= '1';
                for ii in 0 to 256 loop
                    opA_i <= rand_slv(32);

                    for jj in 0 to 256 loop
                        opB_i <= rand_slv(32);

                        for kk in 0 to 1 loop
                            ctrl_alu_i.addn <= bool2bit(kk = 1);

                            wait until rising_edge(clk_i);
                            wait for 100 ps;
    
                            if (ctrl_alu_i.addn = '1') then
                                check(res_o = std_logic_vector(signed(opA_i) - signed(opB_i)), 
                                    "Check: " & to_hstring(res_o) & " != " & to_hstring(opA_i) & " - " & to_hstring(opB_i));
                            else
                                check(res_o = std_logic_vector(signed(opA_i) + signed(opB_i)), 
                                    "Check: " & to_hstring(res_o) & " != " & to_hstring(opA_i) & " + " & to_hstring(opB_i));
                            end if;
                        end loop;
                    end loop;
                end loop;

                -- Test the bitwise operations portion of the ALU
                ctrl_alu_i.res_sel <= "0100";
                for ii in 0 to 256 loop
                    opA_i <= rand_slv(32);

                    for jj in 0 to 256 loop
                        opB_i <= rand_slv(32);

                        for kk in 2 downto 0 loop
                            ctrl_alu_i.funct3(kk) <= '1';

                            wait until rising_edge(clk_i);
                            wait for 100 ps;
    
                            case ctrl_alu_i.funct3 is
                                when "100" =>
                                    check(res_o = (opA_i xor opB_i), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " xor " & to_hstring(opB_i));
                                    
                                when "110" =>
                                    check(res_o = (opA_i or opB_i), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " or " & to_hstring(opB_i));
                            
                                when others =>
                                    check(res_o = (opA_i and opB_i), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " and " & to_hstring(opB_i));
                            
                            end case;
                        end loop;

                        ctrl_alu_i.funct3 <= "000";
                    end loop;
                end loop;

                -- Test the bitshift operations portion of the ALU
                ctrl_alu_i.res_sel <= "0010";
                for ii in 0 to 256 loop
                    opA_i <= rand_slv(32);

                    for jj in 0 to 31 loop
                        opB_i <= to_slv(jj, 32);

                        for kk in 0 to 3 loop
                            local := to_slv(kk, 2);

                            ctrl_alu_i.sright <= local(0);
                            ctrl_alu_i.sarith <= local(1);

                            wait until rising_edge(clk_i);
                            wait for 100 ps;
    
                            case local is
                                when "00" =>
                                    check(res_o = std_logic_vector(shift_left(unsigned(opA_i), jj)), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " sll " & integer'image(jj));
                                    
                                when "01" =>
                                    check(res_o = std_logic_vector(shift_right(unsigned(opA_i), jj)), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " srl " & integer'image(jj));

                                when "10" =>
                                    -- Skip this test, since the barrel shifter core is implemented to support 
                                    -- bit shifting operations but does not handle SLA as it is not a 
                                    -- common command.
                                    --
                                    -- The check is maintained here for if we need to support SLA ever.
                                    -- check(res_o = std_logic_vector(shift_left(signed(opA_i), jj)), 
                                    --     "Check: " & to_hstring(res_o) & " != " & 
                                    --     to_hstring(opA_i) & " sla " & integer'image(jj));

                                when "11" =>
                                    check(res_o = std_logic_vector(shift_right(signed(opA_i), jj)), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " srl " & integer'image(jj));
                            
                                when others =>
                                    check(false);
                            
                            end case;
                        end loop;
                    end loop;
                end loop;

                -- Test the SLT operations portion of the ALU
                ctrl_alu_i.res_sel <= "0001";
                ctrl_alu_i.slt     <= '1';
                for ii in 0 to 256 loop
                    opA_i <= rand_slv(32);

                    for jj in 0 to 256 loop
                        opB_i <= rand_slv(32);

                        for kk in 0 to 1 loop
                            ctrl_alu_i.sltuns <= bool2bit(kk = 1);

                            wait until rising_edge(clk_i);
                            wait for 100 ps;
    
                            case ctrl_alu_i.sltuns is
                                when '0' =>
                                    check(res_o = (31 downto 1 => '0') & bool2bit(signed(opA_i) < signed(opB_i)), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " < " & to_hstring(opB_i));
                                    
                                when '1' =>
                                    check(res_o = (31 downto 1 => '0') & bool2bit(unsigned(opA_i) < unsigned(opB_i)), 
                                        "Check: " & to_hstring(res_o) & " != " & 
                                        to_hstring(opA_i) & " < " & to_hstring(opB_i));

                                when others =>
                                    check(false);
                            
                            end case;
                        end loop;
                    end loop;
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;