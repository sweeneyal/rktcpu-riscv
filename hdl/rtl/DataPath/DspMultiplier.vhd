library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.RiscVDefinitions.all;

entity DspMultiplier is
    port (
        i_clk    : in std_logic;
        i_en     : in std_logic;
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        o_result : out std_logic_vector(31 downto 0);
        o_done   : out std_logic
    );
end entity DspMultiplier;

architecture rtl of DspMultiplier is
    signal opAextended       : signed(63 downto 0);
    signal opBextended       : signed(63 downto 0);
    signal opAextended_reg   : signed(63 downto 0);
    signal opBextended_reg   : signed(63 downto 0);
    signal resultExtended_d1 : signed(127 downto 0);
    signal resultExtended    : signed(127 downto 0);

    type state_t is (IDLE, MULS0, MULS1, DONE);
    signal state : state_t;
begin
    
    OperandExtension: process(i_opA, i_opB, i_funct3)
    begin
        case i_funct3 is
            when cMulFunct3 =>
                opAextended <= resize(signed(i_opA), 64);
                opBextended <= resize(signed(i_opB), 64);
            when cMulhFunct3 =>
                opAextended <= resize(signed(i_opA), 64);
                opBextended <= resize(signed(i_opB), 64);
            when cMulhsuFunct3 =>
                opAextended <= resize(signed(i_opA), 64);
                opBextended <= signed(resize(unsigned(i_opB), 64));
            when others => -- cMulhuFunct3
                opAextended <= signed(resize(unsigned(i_opA), 64));
                opBextended <= signed(resize(unsigned(i_opB), 64));
        end case;
    end process OperandExtension;
    
    MultiplierImplementation: process(i_clk)
    begin
        if rising_edge(i_clk) then
            resultExtended_d1 <= opAextended_reg * opBextended_reg;
            resultExtended    <= resultExtended_d1;
    
            case state is
                when IDLE =>
                    if (i_en = '1') then
                        opAextended_reg <= opAextended;
                        opBextended_reg <= opBextended;
                        state           <= MULS0;
                    end if;
    
                when MULS0 =>
                    state <= MULS1;
    
                when MULS1 =>
                    state <= DONE;
    
                when DONE =>
                    if (i_en = '0') then
                        state <= IDLE;
                    end if;
                    case i_funct3 is
                        when cMulFunct3 =>
                            o_result <= std_logic_vector(resultExtended(31 downto 0));
                        when cMulhFunct3 =>
                            o_result <= std_logic_vector(resultExtended(63 downto 32));
                        when cMulhsuFunct3 =>
                            o_result <= std_logic_vector(resultExtended(63 downto 32));
                        when others =>
                            o_result <= std_logic_vector(resultExtended(63 downto 32));
                    end case;
                    o_done <= '1';
    
                when others =>
                    state <= IDLE;
                    o_done <= '0';
                    
            end case;
        end if;
    end process MultiplierImplementation;
    
    
end architecture rtl;
