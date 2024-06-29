library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity BarrelShift is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;
        i_en     : in std_logic;
        i_right  : in std_logic;
        i_arith  : in std_logic;
        i_opA    : in std_logic_vector(31 downto 0);
        i_shamt  : in std_logic_vector(4 downto 0);
        o_res    : out std_logic_vector(31 downto 0)
    );
end entity BarrelShift;

architecture rtl of BarrelShift is
    constant cXlen : natural := 32;
    constant cNumStages : natural := clog2(cXlen);
    signal bs_level : std_logic_matrix_t(0 to cNumStages)(31 downto 0);
    signal bs_sign  : std_logic;
begin
    
    bs_sign     <= i_opA(31) and i_arith;
    bs_level(0) <= cond_select(i_right = '1', i_opA, reverse(i_opA));

    gBarrelShifter: for g_ii in 0 to cNumStages - 1 generate
        bs_level(g_ii + 1)((cXlen - 1) downto cXlen - (2 ** g_ii)) <= 
            cond_select(i_shamt(g_ii) = '1', 
                ((cXlen - 1) downto cXlen-(2** g_ii) => bs_sign), 
                bs_level(g_ii)((cXlen - 1) downto cXlen-(2** g_ii)));

        bs_level(g_ii + 1)((cXlen - (2 ** g_ii)) - 1 downto 0) <= 
            cond_select(i_shamt(g_ii) = '1', 
                bs_level(g_ii)((cXlen - 1) downto 2 ** g_ii), 
                bs_level(g_ii)((cXlen - (2** g_ii))-1 downto 0));
    end generate gBarrelShifter;

    ResultFlops: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                o_res <= x"00000000";
            else
                if (i_en = '1') then
                    o_res <= cond_select(i_right = '1', bs_level(cNumStages), reverse(bs_level(cNumStages)));
                end if;
            end if;
        end if;
    end process ResultFlops;
    
end architecture rtl;