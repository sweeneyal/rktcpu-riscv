library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity Bus2Axi is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        i_bus_addr   : in std_logic_vector(31 downto 0);
        i_bus_ren    : in std_logic;
        i_bus_wen    : in std_logic_vector(3 downto 0);
        i_bus_wdata  : in std_logic_vector(31 downto 0);
        o_bus_rdata  : out std_logic_vector(31 downto 0);
        o_bus_rvalid : out std_logic;

        o_m_axi_awaddr  : out std_logic_vector(31 downto 0);
        o_m_axi_awprot  : out std_logic_vector(2 downto 0);
        o_m_axi_awvalid : out std_logic;
        i_m_axi_awready : in  std_logic;

        o_m_axi_wdata   : out std_logic_vector(31 downto 0);
        o_m_axi_wstrb   : out std_logic_vector(3 downto 0);
        o_m_axi_wvalid  : out std_logic;
        i_m_axi_wready  : in  std_logic;

        i_m_axi_bresp   : in  std_logic_vector(1 downto 0);
        i_m_axi_bvalid  : in  std_logic;
        o_m_axi_bready  : out std_logic;

        o_m_axi_araddr  : out std_logic_vector(31 downto 0);
        o_m_axi_arprot  : out std_logic_vector(2 downto 0);
        o_m_axi_arvalid : out std_logic;
        i_m_axi_arready : in  std_logic;

        i_m_axi_rdata   : in  std_logic_vector(31 downto 0);
        i_m_axi_rresp   : in  std_logic_vector(1 downto 0);
        i_m_axi_rvalid  : in  std_logic;
        o_m_axi_rready  : out std_logic
    );
end entity Bus2Axi;

architecture rtl of Bus2Axi is
    type state_t is (IDLE, WRITE_SEQUENCE, WRITE_RESPONSE, READ_SEQUENCE, READ_RESPONSE, DONE);
    signal state : state_t := IDLE;

    signal addr_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal data_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal wen_reg  : std_logic_vector(3 downto 0) := "0000";
    signal ren_reg  : std_logic := '0';

    signal awready : std_logic := '0';
    signal wready  : std_logic := '0';
    signal arready : std_logic := '0';
    signal resp    : std_logic_vector(1 downto 0) := "00";
begin
    
    o_bus_rdata  <= data_reg;
    o_bus_rvalid <= bool2bit(state = DONE);

    o_m_axi_awaddr <= addr_reg;
    o_m_axi_araddr <= addr_reg;
    o_m_axi_wdata  <= data_reg;
    o_m_axi_wstrb  <= wen_reg;

    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                o_m_axi_awvalid <= '0';
                o_m_axi_wvalid  <= '0';
                o_m_axi_arvalid <= '0';
                o_m_axi_rready  <= '0';
                o_m_axi_bready  <= '0';
            else
                case state is
                    when IDLE =>
                        addr_reg <= i_bus_addr;
                        ren_reg  <= i_bus_ren;
                        wen_reg  <= i_bus_wen;
                        data_reg <= i_bus_wdata;
                        if (i_bus_ren = '1') then
                            if (any(i_bus_wen) = '1') then
                                state <= WRITE_SEQUENCE;
                            else
                                state <= READ_SEQUENCE;
                            end if;
                        end if;

                    when WRITE_SEQUENCE =>
                        -- Since we're operating with an AXI interface, we need to start a 
                        -- write transaction by transferring on the AXI write address (AW) and
                        -- the AXI write data (W) channels. These will go high simultaneously,
                        -- but since the AXI spec allows for a delay between AW and W transfers in
                        -- a basic write transaction, we're allowing them to complete at different times.
                        o_m_axi_awvalid <= '1';
                        if (i_m_axi_awready = '1') then
                            awready         <= '1';
                            o_m_axi_awvalid <= '0';
                        elsif (awready = '1') then
                            o_m_axi_awvalid <= '0';
                        end if;

                        -- Warning, this may cause the WDATA to be accepted before the AWADDR, which
                        -- may cause bugs.
                        o_m_axi_wvalid <= '1';
                        if (i_m_axi_wready = '1') then
                            wready         <= '1';
                            o_m_axi_wvalid <= '0';
                        elsif (wready = '1') then
                            o_m_axi_wvalid <= '0';
                        end if;

                        -- If we get both transfers complete, then we're ready to go to the response state.
                        if (((awready or i_m_axi_awready) and (wready or i_m_axi_wready)) = '1') then
                            wready  <= '0';
                            awready <= '0';
                            state   <= WRITE_RESPONSE;
                            o_m_axi_wvalid <= '0';
                            o_m_axi_awvalid <= '0';
                            o_m_axi_bready <= '1';
                        end if;
                
                    when WRITE_RESPONSE =>
                        -- Read the bresp and then go to cache fetch.
                        if (i_m_axi_bvalid = '1') then
                            resp           <= i_m_axi_bresp;
                            o_m_axi_bready <= '0';

                            -- If we were doing a write, we can go back to IDLE after 
                            -- updating the metadata to reflect the new data.
                            state <= DONE;
                        end if;
                        
                    when READ_SEQUENCE =>
                        -- We're fetching information from the provided address,
                        -- which means we need to initiate a transaction on the address 
                        -- read (AR) side.
                        if (i_m_axi_arready = '1' and arready = '1') then
                            o_m_axi_arvalid <= '0';
                            o_m_axi_rready <= '1';
                            arready <= '0';
                            state <= READ_RESPONSE;
                        else
                            arready         <= '1';
                            o_m_axi_arvalid <= '1';
                        end if;

                    when READ_RESPONSE =>
                        -- Once the AXI peripheral responds, the data should 
                        -- go directly into the cache without further 
                        -- intervention from this state machine, so we can go back to idle.
                        o_m_axi_rready <= '1';
                        if (i_m_axi_rvalid = '1') then
                            resp           <= i_m_axi_rresp;
                            state          <= DONE;
                            o_m_axi_rready <= '0';
                        end if;
                
                    when DONE =>
                        state   <= IDLE;
                        wready  <= '0';
                        awready <= '0';
                        arready <= '0';

                        o_m_axi_awvalid <= '0';
                        o_m_axi_wvalid  <= '0';
                        o_m_axi_arvalid <= '0';
                        o_m_axi_rready  <= '0';
                        o_m_axi_bready  <= '0';

                end case;
            end if;
        end if;
    end process StateMachine;
    
end architecture rtl;