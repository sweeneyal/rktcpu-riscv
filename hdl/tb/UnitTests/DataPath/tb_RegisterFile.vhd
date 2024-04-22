library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.RiscVDefinitions.all;
    use scrv.DataPathEntities.all;

entity tb_RegisterFile is
    generic (runner_cfg : string);
end entity tb_RegisterFile;

architecture tb of tb_RegisterFile is
    signal clk    : std_logic;
    signal resetn : std_logic;
    signal rs1    : std_logic_vector(4 downto 0);
    signal rs2    : std_logic_vector(4 downto 0);
    signal rd     : std_logic_vector(4 downto 0);
    signal result : std_logic_vector(31 downto 0);
    signal wen    : std_logic;
    signal opA    : std_logic_vector(31 downto 0);
    signal opB    : std_logic_vector(31 downto 0);
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : RegisterFile
    generic map (
        cDataWidth    => 32,
        cAddressWidth => 5
    ) port map (
        i_clk    => clk,
        i_resetn => resetn,
        i_rs1    => rs1,
        i_rs2    => rs2,
        i_rd     => rd,
        i_result => result,
        i_wen    => wen,
        o_opA    => opA,
        o_opB    => opB
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_regfile") then
                rs1    <= "00000";
                rs2    <= "00000";
                rd     <= "00000";
                wen    <= '0';
                result <= x"00000000";
                resetn <= '0';
                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';
                for ii in 0 to 31 loop
                    rd     <= to_slv(ii, 5);
                    result <= to_slv(ii, 32);
                    wen    <= '1';
                    wait until rising_edge(clk);
                    wait for 100 ps;
                    rs1 <= to_slv(ii, 5);
                    if (ii > 0) then
                        rs2 <= to_slv(ii - 1, 5);
                    end if;
                    wait for 100 ps;
                    check(opA = result);
                    if (ii > 0) then
                        check(to_natural(opB) = (to_natural(result) - 1));
                    end if;
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;