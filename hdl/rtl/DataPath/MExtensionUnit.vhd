library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity MExtensionUnit is
    port (
        i_clk    : in std_logic;
        i_opcode : in std_logic_vector(6 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        i_funct7 : in std_logic_vector(6 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        o_result : out std_logic_vector(31 downto 0);
        o_done   : out std_logic
    );
end entity MExtensionUnit;

architecture rtl of MExtensionUnit is
    signal mul_en   : std_logic;
    signal div_en   : std_logic;
    signal issigned : std_logic;
    signal opA_div : unsigned(31 downto 0);
    signal opB_div : unsigned(31 downto 0);
    signal mdone   : std_logic;
    signal mresult : std_logic_vector(31 downto 0);
    signal ddone   : std_logic;
    signal dresult : std_logic_vector(31 downto 0);
    signal rresult : std_logic_vector(31 downto 0);
begin

    InternalControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            mul_en <= '0';
            div_en <= '0';
            if (i_opcode = cMulDivOpcode) then
                if (i_funct3(2) = '1') then
                    div_en <= '1';
                else
                    mul_en <= '1';
                end if;
            end if;
        end if;
    end process InternalControl;

    eDspMult : DspMultiplier
    port map (
        i_clk    => i_clk,
        i_en     => mul_en,
        i_opA    => i_opA,
        i_opB    => i_opB,
        i_funct3 => i_funct3,
        o_result => mresult,
        o_done   => mdone
    );

    issigned <= not i_funct3(0)

    eGdu : GoldschmidtDivisionUnit
    port map (
        i_clk    => i_clk,
        i_en     => div_en,
        i_signed => issigned,
        i_num    => i_opA,
        i_denom  => i_opB,
        o_div    => dresult,
        o_rem    => rresult,
        o_valid  => ddone
    );

    Multiplexor: process(i_funct3, mdone, mresult, ddone, dresult, rresult)
    begin
        if (i_funct3(2) = '0') then
            o_result <= mresult;
        elsif (i_funct3(2 downto 1) = "10") then
            o_result <= dresult;
        elsif (i_funct3(2 downto 1) = "11") then
            o_result <= rresult;
        else
            o_result <= (others => '0');
        end if;
    end process Multiplexor;

    o_done <= ddone or mdone;
    
end architecture rtl;