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

entity tb_GoldschmidtDivisionUnit is
    generic (runner_cfg : string);
end entity tb_GoldschmidtDivisionUnit;

architecture tb of tb_GoldschmidtDivisionUnit is
    signal clk      : std_logic;
    signal en       : std_logic;
    signal issigned : std_logic;
    signal opA      : std_logic_vector(31 downto 0);
    signal opB      : std_logic_vector(31 downto 0);
    signal funct3   : std_logic_vector(2 downto 0);
    signal dresult  : std_logic_vector(31 downto 0);
    signal rresult  : std_logic_vector(31 downto 0);
    signal ddone    : std_logic;
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : entity rktcpu.GoldschmidtDivisionUnit
    port map (
        i_clk    => clk,
        i_en     => en,
        i_signed => issigned,
        i_num    => opA,
        i_denom  => opB,
        o_div    => dresult,
        o_rem    => rresult,
        o_valid  => ddone
    );

    Stimuli: process
        variable opA_int : integer;
        variable opB_int : integer;
        variable div     : std_logic_vector(31 downto 0);
        variable rrem    : std_logic_vector(31 downto 0);
        variable RandData : RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_unsigned_division") then
                en       <= '1';
                opA      <= RandData.RandSlv(x"00000001", x"0FFFFFFF");
                opB      <= RandData.RandSlv(x"00000001", x"0FFFFFFF");
                issigned <= '0';
                wait for 100 ps;
                opA_int := to_integer(opA);
                opB_int := to_integer(opB);
                div     := to_slv(opA_int/opB_int, 32);
                rrem    := to_slv(opA_int rem opB_int, 32);
                for ii in 0 to 11 loop
                    wait until rising_edge(clk);
                    wait for 100 ps;
                end loop;

                check(ddone = '1');
                -- Error occurs because these are not equal to the expected. Fix this;
                check(div   = dresult);
                check(rrem  = rresult);
            elsif run("t_max_unsigned_division") then
                en       <= '1';
                opA      <= RandData.RandSlv(x"80000000", x"FFFFFFFF");
                opB      <= RandData.RandSlv(x"00000001", x"FFFFFFFF");
                issigned <= '0';
                wait for 100 ps;
                -- This test fails because VHDL does not support integers greater than
                -- integer'high. This is a problem because in order to test division, we need
                -- to allow for large integers being divided.
                div  := std_logic_vector(divide(unsigned(opA), unsigned(opB)));
                rrem := std_logic_vector(unsigned(opA) - shape(unsigned(div) * unsigned(opB), 31, 0));
                for ii in 0 to 11 loop
                    wait until rising_edge(clk);
                    wait for 100 ps;
                end loop;

                check(ddone = '1');
                check(div   = dresult);
                check(rrem  = rresult);
            elsif run("t_signed_division") then
                en       <= '1';
                opA      <= RandData.RandSlv(x"00000001", x"FFFFFFFF");
                opB      <= RandData.RandSlv(x"00000001", x"FFFFFFFF");
                issigned <= '1';
                wait for 100 ps;
                div  := std_logic_vector(divide(signed(opA), signed(opB)));
                
                if opA(31) /= opB(31) then
                    if opA(31) = '1' then
                        rrem := std_logic_vector(unsigned(opA) - shape(unsigned(-signed(div)) * unsigned(opB), 31, 0));
                        rrem := std_logic_vector(unsigned(-signed(rrem)));
                    else
                        rrem := std_logic_vector(unsigned(opA) - shape(unsigned(-signed(div)) * unsigned(opB), 31, 0));
                    end if;
                else
                    rrem := std_logic_vector(unsigned(opA) - shape(unsigned(div) * unsigned(opB), 31, 0));
                end if;

                for ii in 0 to 11 loop
                    wait until rising_edge(clk);
                    wait for 100 ps;
                end loop;

                check(ddone = '1');
                -- Error occurs because these are not equal to the expected. Fix this;
                check(div   = dresult);
                check(rrem  = rresult);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;