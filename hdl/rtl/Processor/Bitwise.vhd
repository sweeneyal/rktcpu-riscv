library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity Bitwise is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;
        i_en     : in std_logic;
        i_funct3 : in std_logic_vector(2 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        o_res    : out std_logic_vector(31 downto 0)
    );
end entity Bitwise;

architecture rtl of Bitwise is
begin
    
    PipelinedImplementation: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                o_res  <= x"00000000";
            else
                if (i_en = '1') then
                    case i_funct3 is
                        when "100" =>
                            o_res <= i_opA xor i_opB;
                        when "110" =>
                            o_res <= i_opA or i_opB;
                        when others =>
                            o_res <= i_opA and i_opB;
                    end case;
                end if;
            end if;
        end if;
    end process PipelinedImplementation;
    
end architecture rtl;