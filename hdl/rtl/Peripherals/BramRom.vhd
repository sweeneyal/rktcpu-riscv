library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;

use std.textio.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity BramRom is
    generic (
        cAddressWidth_b : natural;
        cMaxAddress     : natural;
        cDataWidth_b    : natural;
        cInitPath       : string
    );
    port (
        i_clk : in std_logic;

        i_addra   : in std_logic_vector(cAddressWidth_b - 1 downto 0);
        i_ena     : in std_logic;
        o_rdataa  : out std_logic_vector(cDataWidth_b - 1 downto 0);
        o_rvalida : out std_logic;

        i_addrb   : in std_logic_vector(cAddressWidth_b - 1 downto 0);
        i_enb     : in std_logic;
        o_rdatab  : out std_logic_vector(cDataWidth_b - 1 downto 0);
        o_rvalidb : out std_logic
    );
end entity BramRom;

architecture rtl of BramRom is
    file instructions : text;

    impure function initialize (depth, datawidth : natural; init_path : string) return std_logic_matrix_t is
        variable slm : std_logic_matrix_t(0 to depth - 1)(datawidth - 1 downto 0);
        variable instruction    : line;
        variable instructionslv : std_logic_vector(datawidth - 1 downto 0);
        variable idx            : natural;
    begin
        file_open(instructions, init_path, read_mode);
        while not endfile(instructions) loop
            readline(instructions, instruction);
            hread(instruction, instructionslv);
            slm(idx) := instructionslv;
            idx := idx + 1;
        end loop;
        file_close(instructions);
        return slm;
    end function;

    shared variable ram : std_logic_matrix_t(0 to cMaxAddress - 1)(cDataWidth_b - 1 downto 0) 
        := initialize(cMaxAddress, cDataWidth_b, cInitPath);
begin
    
    RomAddrAControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            o_rvalida <= i_ena;
            if (i_ena = '1') then
                o_rdataa <= ram(to_natural(i_addra));
            else
                o_rdataa <= (others => '0');
            end if;
        end if;
    end process RomAddrAControl;

    RomAddrBControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            o_rvalidb <= i_enb;
            if (i_enb = '1') then
                o_rdatab <= ram(to_natural(i_addrb));
            else
                o_rdatab <= (others => '0');
            end if;
        end if;
    end process RomAddrBControl;
    
end architecture rtl;