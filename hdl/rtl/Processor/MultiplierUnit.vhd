library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;

entity MultiplierUnit is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        i_ctrl_mul : in mul_controls_t;
        i_opA      : in std_logic_vector(31 downto 0);
        i_opB      : in std_logic_vector(31 downto 0);

        o_res : out std_logic_vector(31 downto 0)
    );
end entity MultiplierUnit;

architecture rtl of MultiplierUnit is
    signal opA : std_logic_vector(31 downto 0) := (others => '0');
    signal opB : std_logic_vector(31 downto 0) := (others => '0');
    signal res0 : std_logic_vector(63 downto 0) := (others => '0');
    signal res1 : std_logic_vector(63 downto 0) := (others => '0');
begin
    
    -- Should infer a 5 stage pipelined multiplier. 
    MultiplierInferred: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                opA <= (others => '0');
                opB <= (others => '0');
                res0 <= (others => '0');
                res1 <= (others => '0');
                o_res <= (others => '0');
            else
                opA <= i_opA;
                opB <= i_opB;
                if (i_ctrl_mul.uns = "11") then
                    res0 <= std_logic_vector(unsigned(opA) * unsigned(opB));
                elsif (i_ctrl_mul.uns = "01") then
                    res0 <= std_logic_vector(resize(
                        resize(signed(opA), 33) * signed(resize(unsigned(opB), 33)),
                        64));
                else
                    res0 <= std_logic_vector(signed(opA) * signed(opB));
                end if;
                res1 <= res0;
                o_res <= res1;
            end if;
        end if;
    end process MultiplierInferred;
    
end architecture rtl;