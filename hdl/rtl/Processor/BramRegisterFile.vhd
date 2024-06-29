library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;

entity BramRegisterFile is
    generic (
        cGenerateLoggers : boolean := false
    );
    port (
        i_clk : in std_logic;
        i_resetn : in std_logic;

        i_rs1    : in std_logic_vector(4 downto 0);
        o_opA    : out std_logic_vector(31 downto 0);
        i_rs2    : in std_logic_vector(4 downto 0);
        o_opB    : out std_logic_vector(31 downto 0);

        i_rd     : in std_logic_vector(4 downto 0);
        i_rdwen  : in std_logic;
        i_res    : in std_logic_vector(31 downto 0)
    );
end entity BramRegisterFile;

architecture rtl of BramRegisterFile is
begin
    
    eRegisterCopy0 : entity rktcpu.DualPortBram
    generic map (
        cAddressWidth => 5,
        cMaxAddress   => 32,
        cDataWidth    => 32
    ) port map (
        i_clk => i_clk,

        i_addra  => i_rs1,
        i_ena    => '1',
        i_wena   => '0',
        i_wdataa => x"00000000",
        o_rdataa => o_opA,

        i_addrb  => i_rd,
        i_enb    => '1',
        i_wenb   => i_rdwen,
        i_wdatab => i_res,
        o_rdatab => open
    );

    eRegisterCopy1 : entity rktcpu.DualPortBram
    generic map (
        cAddressWidth => 5,
        cMaxAddress   => 32,
        cDataWidth    => 32
    ) port map (
        i_clk => i_clk,

        i_addra  => i_rs2,
        i_ena    => '1',
        i_wena   => '0',
        i_wdataa => x"00000000",
        o_rdataa => o_opB,

        i_addrb  => i_rd,
        i_enb    => '1',
        i_wenb   => i_rdwen,
        i_wdatab => i_res,
        o_rdatab => open
    );

    -- gGenerateLoggers: if (cGenerateLoggers) generate
    --     Loggers: process(i_rd, i_rdwen, i_res)
    --     begin
    --         if (i_rdwen = '1') then
    --             report "RD: " & to_hstring(i_rd) & " RES: " & to_hstring(i_res);
    --         end if;
    --     end process Loggers;
    -- end generate gGenerateLoggers;
    
end architecture rtl;