library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity SimpleFifo is
    generic (
        cAddressWidth : natural;
        cDataWidth    : natural
    );
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        o_empty  : out std_logic;
        o_aempty : out std_logic;
        o_afull  : out std_logic;
        o_full   : out std_logic;
        
        i_data   : in std_logic_vector(cDataWidth - 1 downto 0);
        i_dvalid : in std_logic;

        i_pop    : in std_logic;
        o_data   : out std_logic_vector(cDataWidth - 1 downto 0);
        o_dvalid : out std_logic
    );
end entity SimpleFifo;

architecture rtl of SimpleFifo is
    signal empty  : std_logic;
    signal aempty : std_logic;
    signal afull  : std_logic;
    signal full   : std_logic;
    signal addra  : std_logic_vector(cAddressWidth - 1 downto 0);
    signal addrb  : std_logic_vector(cAddressWidth - 1 downto 0);
    signal enb    : std_logic;
    signal wena   : std_logic;
begin

    wena <= not full and i_dvalid;
    
    FifoHeadControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                head <= 0;
            else
                if (wena = '1') then
                    if head < cDepth - 1 then
                        head <= head + 1;
                    else
                        head <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process FifoHeadControl;

    enb <= not empty and i_pop;

    FifoHeadControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                tail <= 0;
            else
                if (enb = '1') then
                    if tail < cDepth - 1 then
                        tail <= tail + 1;
                    else
                        tail <= 0;
                    end if;
                end if;
            end if;

            o_dvalid <= enb;
        end if;
    end process FifoHeadControl;

    FlagComputation: process(head, tail)
    begin
        if tail > head then
            size := head + cDepth - tail;
        else
            size := head - tail;
        end if;

        full   <= bool2bit(size = cDepth - 1);
        afull  <= bool2bit(size = cDepth - 2);
        aempty <= bool2bit(size = 1);
        empty  <= bool2bit(size = 0);
    end process FlagComputation;

    o_empty  <= empty;
    o_aempty <= aempty;
    o_afull  <= afull;
    o_full   <= full;

    addra <= to_slv(head, cAddressWidth);
    addrb <= to_slv(tail, cAddressWidth);

    eBram : DualPortBram
    generic map (
        cAddressWidth => cAddressWidth,
        cMaxAddress   => 2 ** cAddressWidth - 1
        cDataWidth    => cDataWidth
    ) port map (
        i_clk => i_clk,

        i_addra  => addra,
        i_ena    => wena,
        i_wena   => wena,
        i_wdataa => i_data,
        o_rdataa => open

        i_addrb  => addrb,
        i_enb    => enb,
        i_wenb   => '0',
        i_wdatab => (others => '0'),
        o_rdatab => o_data
    );
    
end architecture rtl;