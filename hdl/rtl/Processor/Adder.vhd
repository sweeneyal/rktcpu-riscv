library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity Adder is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;
        i_en     : in std_logic;
        i_addn   : in std_logic;
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        o_res    : out std_logic_vector(31 downto 0)
    );
end entity Adder;

architecture rtl of Adder is
    signal opB   : signed(31 downto 0);
begin
    
    AddSubtractOperation: process(i_opB, i_addn)
    begin
        if (i_addn = '1') then
            opB <= -signed(i_opB);
        else
            opB <= signed(i_opB);
        end if;
    end process AddSubtractOperation;
    
    PipelinedImplementation: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                o_res <= x"00000000";
            else
                if (i_en = '1') then
                    o_res <= std_logic_vector(signed(i_opA) + opB);
                end if;
            end if;
        end if;
    end process PipelinedImplementation;
    
end architecture rtl;