
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
begin
    
    OperandExtension: process(i_opA, i_opB, i_funct3)
    begin
        case funct3 is
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
            resultExtended_d1 <= opAextended * opBextended;
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
                            o_result <= resultExtended(31 downto 0);
                        when cMulhFunct3 =>
                            o_result <= resultExtended(63 downto 32);
                        when cMulhsuFunct3 =>
                            o_result <= resultExtended(63 downto 32);
                        when others =>
                            o_result <= resultExtended(63 downto 32);
                    end case;
                    o_done <= '1';
    
                when others =>
                    state <= IDLE;
                    o_done <= '0';
                    
            end case;
        end if;
    end process MultiplierImplementation;
    
    
end architecture rtl;
