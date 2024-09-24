library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity FetchEngine is
    port (
        i_clk : in std_logic;
        i_resetn : in std_logic;

        o_pc    : out std_logic_vector(31 downto 0);
        o_iren  : out std_logic;
        i_stall : in std_logic;
        o_rpc   : out std_logic_vector(31 downto 0);

        i_pcwen : in std_logic;
        i_pc    : in std_logic_vector(31 downto 0)
    );
end entity FetchEngine;

architecture rtl of FetchEngine is
    signal pc   : unsigned(31 downto 0) := x"00000000";
    signal rpc  : unsigned(31 downto 0) := x"00000000";
    signal oreq : std_logic := '0';
    signal dpc  : unsigned(31 downto 0) := x"00000000";
begin

    o_pc   <= std_logic_vector(pc);
    o_rpc  <= std_logic_vector(rpc);
    o_iren <= oreq;
    
    Controller: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                pc   <= x"00000000";
                rpc  <= x"00000000";
                oreq <= '0';
            else
                if (i_pcwen = '1') then
                    pc   <= unsigned(i_pc);
                    rpc  <= pc;
                    oreq <= '0';
                elsif (oreq = '0') then
                    oreq <= not (i_stall);
                else
                    pc  <= pc + 4;
                    rpc <= pc;
                    if (i_stall = '1') then
                        oreq <= '0';
                    else
                        oreq <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process Controller;
    
end architecture rtl;