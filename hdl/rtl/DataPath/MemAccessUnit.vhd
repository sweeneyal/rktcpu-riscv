library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;
    use universal.CommonTypesPkg.all;

entity MemoryAccessUnit is
    port (
        i_clk    : in std_logic;
        i_opcode : in std_logic_vector(6 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_itype  : in std_logic_vector(11 downto 0);
        i_stype  : in std_logic_vector(11 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        
        o_addr : out std_logic_vector(31 downto 0);
        o_men  : out std_logic;
        o_mwen : out std_logic_vector(3 downto 0);

        i_rvalid : in  std_logic;
        i_rdata  : in  std_logic_vector(31 downto 0);

        o_data  : out std_logic_vector(31 downto 0);
        o_ldone : out std_logic;
        o_sdone : out std_logic
    );
end entity MemoryAccessUnit;

architecture rtl of MemoryAccessUnit is
    type state_t is (IDLE, STORE_DATA, LOAD_DATA, LOAD_FINISH, LOAD_DONE, STORE_DONE);
    signal addr  : std_logic_vector(31 downto 0);
    signal immed : std_logic_vector(11 downto 0);
    signal wen   : std_logic_vector(3 downto 0);
    signal data  : std_logic_vector(31 downto 0);
begin

    immed <= cond_select(i_opcode = cLoadOpcode, i_itype, i_stype);
    addr  <= std_logic_vector(s32_t(i_opA) + to_s32(i_itype));

    EnableCalculation: process(addr, i_funct3)
    begin
        case i_funct3(1 downto 0) is
            when "00" =>
                case addr(1 downto 0) is
                    when "00" =>
                        wen <= "0001";
                    when "01" =>
                        wen <= "0010";
                    when "10" =>
                        wen <= "0100";
                    when "11" =>
                        wen <= "1000";
                    when others =>
                        wen <= "0000";
                end case;

            when "01" =>
                case addr(1 downto 0) is
                    when "00" =>
                        wen <= "0011";
                    when "01" =>
                        wen <= "0110";
                    when "10" =>
                        wen <= "1100";
                    when "11" =>
                        wen <= "0000";
                    when others =>
                        wen <= "0000";
                end case;

            when "10" => 
                case addr(1 downto 0) is
                    when "00" =>
                        wen <= "1111";
                    when "01" =>
                        wen <= "0000";
                    when "10" =>
                        wen <= "0000";
                    when "11" =>
                        wen <= "0000";
                    when others =>
                        wen <= "0000";
                end case;

            when others =>
                wen <= "0000";
        end case;
    end process EnableCalculation;

    -- Unaligned reads and writes are assumed to be invalid.
    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            case mengine.state is
                when IDLE =>
                    mengine.addr <= addr(31 downto 2) & "00";
                    if i_opcode = cLoadOpcode then
                        mengine.state <= LOAD_DATA;
                        mengine.en    <= '1';
                        mengine.wen   <= (others => '0');
                    elsif i_opcode = cStoreOpcode then
                        mengine.state <= STORE_DATA;
                        mengine.en    <= '1';
                        mengine.wen   <= wen;
                    else
                        mengine.en    <= '0';
                        mengine.wen   <= (others => '0');
                    end if;

                when LOAD_DATA =>
                    if (i_rvalid = '1') then
                        mengine.data  <= i_rdata;
                        mengine.state <= LOAD_FINISH;
                    end if;

                when LOAD_FINISH =>
                    case i_funct3 is
                        when "000" =>
                            data <= std_logic_vector(resize(signed(mengine.data(7 downto 0))));
                        when "001" =>
                            data <= std_logic_vector(resize(signed(mengine.data(15 downto 0))));
                        when "010" =>
                            data <= mengine.data;
                        when "100" =>
                            data <= std_logic_vector(resize(unsigned(mengine.data(7 downto 0))));
                        when "101" =>
                            data <= std_logic_vector(resize(unsigned(mengine.data(15 downto 0))));
                        when others =>
                            data <= mengine.data;
                    end case;

                    mengine.state <= LOAD_DONE;

                when STORE_DATA =>
                    if (i_accepted = '1') then
                        mengine.state <= STORE_DONE;
                        mengine.en    <= '0';
                        mengine.wen   <= (others => '0');
                    end if;                    
            
                when others =>
                    mengine.state <= IDLE;
                    mengine.en    <= '0';
                    mengine.wen   <= (others => '0');
            
            end case;
        end if;
    end process StateMachine;

    o_addr  <= mengine.addr;
    o_men   <= mengine.en;
    o_mwen  <= mengine.wen;
    o_data  <= data;
    o_ldone <= bool2bit(mengine.state = LOAD_DONE);
    o_sdone <= bool2bit(mengine.state = STORE_DONE);
    
end architecture rtl;