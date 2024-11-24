library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity FetchEngine is
    port (
        i_clk : in std_logic;
        i_resetn : in std_logic;

        o_pc     : out std_logic_vector(31 downto 0);
        o_iren   : out std_logic;
        i_stall  : in std_logic;
        o_rpc    : out std_logic_vector(31 downto 0);
        i_ivalid : in std_logic;

        i_pcwen : in std_logic;
        i_pc    : in std_logic_vector(31 downto 0)
    );
end entity FetchEngine;

architecture rtl of FetchEngine is
    type state_t is (RESET, INIT, ACTIVE);
    signal state : state_t := RESET;
    signal pc    : unsigned(31 downto 0) := x"00000000";
    signal rpc   : unsigned(31 downto 0) := x"00000000";
    signal dpc   : unsigned(31 downto 0) := x"00000000";
begin

    o_pc   <= std_logic_vector(rpc);
    o_rpc  <= std_logic_vector(dpc);

    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                o_iren <= '0';
                state  <= RESET;
                pc     <= x"00000000";
                rpc    <= x"00000000";
                dpc    <= x"00000000";
            else
                case state is
                    when RESET =>
                        o_iren <= '1';
                        pc     <= pc + 4;
                        rpc    <= pc;
                        dpc    <= rpc;
                        state  <= INIT;

                    when INIT =>
                        -- We don't expect to see anything yet, so allow the pcs to update.
                        o_iren <= '1';
                        pc     <= pc + 4;
                        rpc    <= pc;
                        dpc    <= rpc;
                        state  <= ACTIVE;
                        
                    when ACTIVE =>
                        if (i_pcwen = '1') then
                            pc     <= unsigned(i_pc);
                            rpc    <= pc;
                            dpc    <= rpc;
                            o_iren <= '0';

                            state  <= RESET;
                        elsif (i_ivalid = '1' and i_stall = '0') then
                            pc     <= pc + 4;
                            rpc    <= pc;
                            dpc    <= rpc;
                            o_iren <= '1';
                        else
                            o_iren <= '0';
                        end if;
                
                end case;
            end if;
        end if;
    end process StateMachine;
    
end architecture rtl;