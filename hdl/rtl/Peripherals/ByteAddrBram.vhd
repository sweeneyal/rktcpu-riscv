library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;

entity ByteAddrBram is
    generic (
        cAddressWidth_b : natural := 32;
        cMaxAddress     : natural := 4096;
        cWordWidth_B    : natural range 1 to 8 := 4;
        cVerboseMode    : boolean := false
    );
    port (
        i_clk : in std_logic;

        i_addra   : in std_logic_vector(cAddressWidth_b - 1 downto 0);
        i_ena     : in std_logic;
        i_wena    : in std_logic_vector(3 downto 0);
        i_wdataa  : in std_logic_vector(8 * cWordWidth_B - 1 downto 0);
        o_rdataa  : out std_logic_vector(8 * cWordWidth_B - 1 downto 0);
        o_rvalida : out std_logic;

        i_addrb   : in std_logic_vector(cAddressWidth_b - 1 downto 0);
        i_enb     : in std_logic;
        i_wenb    : in std_logic_vector(3 downto 0);
        i_wdatab  : in std_logic_vector(8 * cWordWidth_B - 1 downto 0);
        o_rdatab  : out std_logic_vector(8 * cWordWidth_B - 1 downto 0);
        o_rvalidb : out std_logic
    );
end entity ByteAddrBram;

architecture rtl of ByteAddrBram is
    function generate_id(idx : natural) return string is
    begin
        return integer'image(idx);
    end function;
begin
    
    gGenerateBrams: for g_ii in 0 to cWordWidth_B - 1 generate
        
        eByteBram : entity rktcpu.DualPortBram
        generic map (
            cAddressWidth_b => cAddressWidth_b - 2,
            cMaxAddress     => cMaxAddress/4,
            cDataWidth_b    => 8,
            cVerboseMode    => cVerboseMode,
            cRamID          => generate_id(g_ii)
        ) port map (
            i_clk => i_clk,
    
            i_addra  => i_addra(cAddressWidth_b - 1 downto 2),
            i_ena    => i_ena,
            i_wena   => i_wena(g_ii),
            i_wdataa => i_wdataa(8 * (g_ii + 1) - 1 downto 8 * g_ii),
            o_rdataa => o_rdataa(8 * (g_ii + 1) - 1 downto 8 * g_ii),
    
            i_addrb  => i_addrb(cAddressWidth_b - 1 downto 2),
            i_enb    => i_enb,
            i_wenb   => i_wenb(g_ii),
            i_wdatab => i_wdatab(8 * (g_ii + 1) - 1 downto 8 * g_ii),
            o_rdatab => o_rdatab(8 * (g_ii + 1) - 1 downto 8 * g_ii)
        );

    end generate gGenerateBrams;

    Rvalids: process(i_clk)
    begin
        if rising_edge(i_clk) then
            o_rvalida <= i_ena;
            o_rvalidb <= i_enb;
        end if;
    end process Rvalids;

end architecture rtl;