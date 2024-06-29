library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;

entity AluCore is
    port (
        i_clk      : in std_logic;
        i_resetn   : in std_logic;
        i_ctrl_alu : in alu_controls_t;
        i_stall    : in std_logic;
        i_opA      : in std_logic_vector(31 downto 0);
        i_opB      : in std_logic_vector(31 downto 0);
        o_res      : out std_logic_vector(31 downto 0)
    );
end entity AluCore;

architecture rtl of AluCore is
    signal en          : std_logic := '0';
    signal adder_res   : std_logic_vector(31 downto 0) := x"00000000";
    signal slt_res     : std_logic_vector(31 downto 0) := x"00000000";
    signal bitwise_res : std_logic_vector(31 downto 0) := x"00000000";
    signal shift_res   : std_logic_vector(31 downto 0) := x"00000000";
begin
    
    en <= not i_stall;

    -- ADD/I, SUB/I, SLT/U/I
    eAdder : entity rktcpu.Adder
    port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,
        i_en     => en,
        i_addn   => i_ctrl_alu.addn,
        i_opA    => i_opA,
        i_opB    => i_opB,
        o_res    => adder_res
    );

    SltAndSltu: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                slt_res <= x"00000000";
            else
                if (en = '1') then
                    if (i_ctrl_alu.slt = '1') then
                        if (i_ctrl_alu.sltuns = '1') then
                            slt_res <= (31 downto 1 => '0') & bool2bit(unsigned(i_opA) < unsigned(i_opB));
                        else
                            slt_res <= (31 downto 1 => '0') & bool2bit(signed(i_opA) < signed(i_opB));
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process SltAndSltu;

    -- XOR/I, OR/I, AND/I
    eBitwise : entity rktcpu.Bitwise
    port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,
        i_en     => en,
        i_funct3 => i_ctrl_alu.funct3,
        i_opA    => i_opA,
        i_opB    => i_opB,
        o_res    => bitwise_res
    );

    -- SLL/I, SRL/I, SRA/I
    eBarrel : entity rktcpu.BarrelShift
    port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,
        i_en     => en,
        i_right  => i_ctrl_alu.sright,
        i_arith  => i_ctrl_alu.sarith,
        i_opA    => i_opA,
        i_shamt  => i_opB(4 downto 0),
        o_res    => shift_res
    );

    ResultSelect: process(i_ctrl_alu, adder_res, bitwise_res, shift_res, slt_res)
    begin
        if (i_ctrl_alu.res_sel(3) = '1') then
            o_res <= adder_res;
        elsif (i_ctrl_alu.res_sel(2) = '1') then
            o_res <= bitwise_res;
        elsif (i_ctrl_alu.res_sel(1) = '1') then
            o_res <= shift_res;
        elsif (i_ctrl_alu.res_sel(0) = '1') then
            o_res <= slt_res;
        else
            o_res <= x"00000000";
        end if;
    end process ResultSelect;
    
end architecture rtl;