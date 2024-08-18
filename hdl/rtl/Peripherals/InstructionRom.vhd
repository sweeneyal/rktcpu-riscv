library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;

entity InstructionRom is
    generic (
        cInstructionHexPath : string;
        cMaxAddress         : natural
    );
    port (
        i_clk          : in std_logic;
        i_instr_addr   : in std_logic_vector(31 downto 0);
        i_instr_ren    : in std_logic;
        i_instr_wen    : in std_logic_vector(3 downto 0);
        i_instr_wdata  : in std_logic_vector(31 downto 0);
        o_instr_rdata  : out std_logic_vector(31 downto 0);
        o_instr_rvalid : out std_logic
    );
end entity InstructionRom;

architecture rtl of InstructionRom is
begin
    
    eRom : entity rktcpu.BramRom
    generic map (
        cAddressWidth_b => 32,
        cMaxAddress     => cMaxAddress / 4,
        cDataWidth_b    => 32,
        cInitPath       => cInstructionHexPath
    ) port map (
        i_clk => i_clk,

        i_addra   => i_instr_addr(31 downto 2),
        i_ena     => i_instr_ren,
        o_rdataa  => o_instr_rdata,
        o_rvalida => o_instr_rvalid,

        i_addrb   => (others => '0'),
        i_enb     => '0',
        o_rdatab  => open,
        o_rvalidb => open
    );
    
end architecture rtl;