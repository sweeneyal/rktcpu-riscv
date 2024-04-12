library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.Control.all;

entity FetchEngine is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;
        i_pc     : in std_logic_vector(31 downto 0);
        i_pcwen  : in std_logic;
        
        o_pc     : out std_logic_vector(31 downto 0);
        o_pcren  : out std_logic;
        i_instr  : in std_logic_vector(31 downto 0);
        i_ivalid : in std_logic;

        i_ren    : in std_logic;
        o_instr  : out std_logic_vector(31 downto 0);
        o_ivalid : out std_logic;
        o_empty  : out std_logic;
        o_full   : out std_logic
    );
end entity FetchEngine;

architecture rtl of FetchEngine is
    type state_t is (FETCH_RESET, FETCH_REQUEST, FETCH_IDLE);
    type fetch_engine_t is record
        state  : state_t;
        pc     : unsigned(31 downto 0);
    end record fetch_engine_t;
    signal fetch_engine : fetch_engine_t;

    signal resetn : std_logic;
    signal empty  : std_logic;
    signal aempty : std_logic;
    signal afull  : std_logic;
    signal full   : std_logic;
begin

    -- This state machine lacks any acknowledgement structures, essentially, blink-and-you-miss-it.
    -- If we start playing games with the clocks, then definitely add some rigor here.
    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                fetch_engine.state <= FETCH_RESET;
            else
                case fetch_engine.state is
                    -- Reset the FIFO and start requesting more data.
                    when FETCH_RESET =>
                        fetch_engine.state <= FETCH_REQUEST;

                    -- When in idle, wait until the FIFO is not full to start requesting.
                    when FETCH_IDLE =>
                        if (i_pcwen = '1') then
                            fetch_engine.state <= FETCH_RESET;
                            fetch_engine.pc    <= unsigned(i_pc);
                        elsif (full = '0') then
                            fetch_engine.state <= FETCH_REQUEST;
                        end if;

                    -- Initiate a request and wait for a result from memory. Or, if we get a
                    -- new PC to start from, go to reset to reinitiate fetch engine.
                    -- Continuously queue instructions up 
                    when FETCH_REQUEST =>
                        if (i_pcwen = '1') then
                            fetch_engine.state <= FETCH_RESET;
                            fetch_engine.pc    <= unsigned(i_pc);
                        else
                            if (i_ivalid = '1') then
                                -- Check if we're going to get a full on the next cycle,
                                -- thereby avoiding a cycle when we can afford it.
                                if (afull = '1') then
                                    fetch_engine.state <= FETCH_IDLE;
                                end if;
                                fetch_engine.pc <= fetch_engine.pc + 1;
                            end if;
                        end if;

                    when others =>
                        fetch_engine.state <= FETCH_RESET;
                
                end case;
            end if;
        end if;
    end process StateMachine;

    -- Same conditions just inverted.
    resetn <= not bool2bit(i_resetn = '0' or fetch_engine.state = FETCH_RESET);

    eFifo : SimpleFifo
    generic map (
        cAddressWidth => 9,
        cDataWidth    => 32
    ) port map (
        i_clk    => i_clk,
        i_resetn => resetn,

        o_empty  => empty,
        o_aempty => aempty,
        o_afull  => afull,
        o_full   => full,
        
        i_data   => i_instr,
        i_dvalid => i_ivalid,

        i_pop    => i_ren,
        o_data   => o_instr,
        o_dvalid => o_ivalid
    );

    o_pc    <= fetch_engine.pc;
    -- This will try to prevent unnecessary fetches when the PC changes.
    o_pcren <= bool2bit(fetch_engine.state = FETCH_REQUEST and i_pcwen = '0');
    o_empty <= empty;
    o_full  <= full;
    
end architecture rtl;