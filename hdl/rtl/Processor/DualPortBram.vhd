library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity DualPortBram is
    generic (
        cAddressWidth : natural := 30;
        cMaxAddress   : natural := 4096;
        cDataWidth    : natural := 32
    );
    port (
        i_clk : in std_logic;

        i_addra  : in std_logic_vector(cAddressWidth - 1 downto 0);
        i_ena    : in std_logic;
        i_wena   : in std_logic;
        i_wdataa : in std_logic_vector(cDataWidth - 1 downto 0);
        o_rdataa : out std_logic_vector(cDataWidth - 1 downto 0);

        i_addrb  : in std_logic_vector(cAddressWidth - 1 downto 0);
        i_enb    : in std_logic;
        i_wenb   : in std_logic;
        i_wdatab : in std_logic_vector(cDataWidth - 1 downto 0);
        o_rdatab : out std_logic_vector(cDataWidth - 1 downto 0)
    );
end entity DualPortBram;

architecture rtl of DualPortBram is
    function initialize (depth, datawidth : natural) return std_logic_matrix_t is
        variable slm : std_logic_matrix_t(0 to depth - 1)(datawidth - 1 downto 0);
    begin
        for ii in 0 to depth - 1 loop
            slm(ii) := (others => '0');
        end loop;
        return slm;
    end function;

    shared variable ram : std_logic_matrix_t(0 to cMaxAddress - 1)(cDataWidth - 1 downto 0) 
        := initialize(cMaxAddress, cDataWidth);
begin
    
    RamAddrAControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_ena = '1') then
                o_rdataa <= ram(to_natural(i_addra));
                if (i_wena = '1') then
                    ram(to_natural(i_addra)) := i_wdataa;
                end if;
            end if;
        end if;
    end process RamAddrAControl;

    RamAddrBControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_enb = '1') then
                o_rdatab <= ram(to_natural(i_addrb));
                if (i_wenb = '1') then
                    ram(to_natural(i_addrb)) := i_wdatab;
                end if;
            end if;
        end if;
    end process RamAddrBControl;

end architecture rtl;