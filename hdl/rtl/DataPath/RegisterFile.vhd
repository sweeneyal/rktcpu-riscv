library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity RegisterFile is
    generic (
        cDataWidth        : natural := 32;
        cAddressWidth     : natural := 5
    );
    port (
        i_clk    : in  std_logic;
        i_resetn : in  std_logic;
        i_rs1    : in  std_logic_vector(cAddressWidth - 1 downto 0);
        i_rs2    : in  std_logic_vector(cAddressWidth - 1 downto 0);
        i_rd     : in  std_logic_vector(cAddressWidth - 1 downto 0);
        i_result : in  std_logic_vector(cDataWidth - 1 downto 0);
        i_wen    : in  std_logic;
        o_opA    : out std_logic_vector(cDataWidth - 1 downto 0);
        o_opB    : out std_logic_vector(cDataWidth - 1 downto 0)
    );
end entity RegisterFile;

architecture rtl of RegisterFile is
    constant cNumAddresses : natural := 2**cAddressWidth;
    signal registers : std_logic_matrix_t(0 to cNumAddresses - 1)(cDataWidth - 1 downto 0);
begin

    o_opA <= registers(to_natural(i_rs1));
    o_opB <= registers(to_natural(i_rs2));

    RegisterWriteControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                for ii in 0 to cNumAddresses - 1 loop
                    registers(ii) <= (others => '0');
                end loop;
            else
                if (i_wen = '1') then
                    registers(to_natural(i_rd)) <= i_result;
                end if;
            end if;
        end if;
    end process RegisterWriteControl;
    
end architecture rtl;