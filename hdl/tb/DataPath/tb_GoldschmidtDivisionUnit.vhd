library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilityPkg.all;

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
    
    CreateClock(clock=>clk, period=>5 ns);

    eDut : GoldschmidtDivisionUnit
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
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_basic_division") then
                en      <= '1';
                opA     <= rand_slv(32);
                opB     <= rand_slv(32);
                opA_int := to_integer(opA);
                opB_int := to_integer(opB);
                div     := to_slv(opA_int/opB_int, 32);
                rrem    := to_slv(opA_int rem opB_int, 32);
                for ii in 0 to 11 loop
                    wait until rising_edge(clk);
                    wait for 100 ps;
                end loop;

                check(ddone = '1');
                check(div   = dresult);
                check(rrem  = rresult);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;