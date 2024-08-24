library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity GpioRegister is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;
        i_ren    : in std_logic;
        i_wen    : in std_logic_vector(3 downto 0);
        i_wdata  : in std_logic_vector(31 downto 0);
        o_rdata  : out std_logic_vector(31 downto 0);
        o_gpio   : out std_logic_vector(31 downto 0)
    );
end entity GpioRegister;

architecture rtl of GpioRegister is
    signal gpio : std_logic_vector(31 downto 0);
begin
    
    GpioControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_resetn = '0' then
                gpio <= x"00000000";
            else
                if (i_ren = '1') then
                    o_rdata <= gpio;
                    for ii in 0 to 3 loop
                        if (i_wen(ii) = '1') then
                            gpio(8 * (ii + 1) - 1 downto 8 * ii) <= i_wdata(8 * (ii + 1) - 1 downto 8 * ii);
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process GpioControl;

    o_gpio <= gpio;
    
end architecture rtl;