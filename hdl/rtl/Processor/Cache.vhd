library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;
    use rktcpu.RiscVDefinitions.all;
    use rktcpu.CsrDefinitions.all;

entity Cache is
    generic (
        cCacheableMemoryRegion : region_t := (x"00000000", x"000FFFFF")
        cCacheSize_B           : natural := 32768
    );
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        i_bus_addr   : in std_logic_vector(31 downto 0);
        i_bus_ren    : in std_logic;
        i_bus_wen    : in std_logic_vector(3 downto 0);
        i_bus_wdata  : in std_logic_vector(31 downto 0);
        o_bus_wready : out std_logic;
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
end entity Cache;

architecture rtl of Cache is
    constant cNumCachelines        : natural := cCacheSize_B / 4;
    constant cCachelineAddrWidth_b : natural := clog2(cCacheSize_B);
    constant cMemAddrWidth_b       : natural := 32 - clog2(cCacheSize_B);
    constant cMetaDataWidth_b      : natural := cMemAddrWidth_b + 2;

    constant cValid : natural := cMetaDataWidth_b - 1;
    constant cDirty : natural := cMetaDataWidth_b - 2;

    signal cacheline : std_logic_vector(cCachelineAddrWidth_b - 1 downto 0) := (others => '0');
    signal memaddr   : std_logic_vector(cMemAddrWidth_b - 1 downto 0) := (others => '0');
    signal metadata  : std_logic_vector(cMetaDataWidth_b - 1 downto 0) := (others => '0');

    signal wdata : std_logic_vector(31 downto 0) := (others => '0');
    signal wen   : std_logic := '0';
begin
    
    -- When an CACHE_FETCH occurs, we need to receive the data from the memory peripheral
    -- as quickly as possible. This means we need to treat the AXI address we requested (new_addr)
    -- as a bus input, and slice it into the two categories.
    cacheline_axi <= new_addr(cCachelineAddrWidth_b - 1 downto 0);
    memaddr_axi   <= new_addr(31 downto cCachelineAddrWidth_b);

    -- Further, we need to use the AXI signaling as well as the state machine to only allow writes under
    -- specific conditions.
    cache_en  <= i_m_axi_rvalid & bool2bit(state = CACHE_FETCH_RESP);
    cache_wen <= cache_en & cache_en & cache_en & cache_en;

    eBram : entity rktcpu.ByteAddrBram
    generic map (
        cAddressWidth_b => cCachelineAddrWidth_b,
        cMaxAddress     => cCacheSize_B - 1,
        cWordWidth_B    => 4
    ) port map (
        i_clk => i_clk,

        i_addra   => cacheline,
        i_ena     => i_bus_ren,
        i_wena    => i_bus_wen,
        i_wdataa  => i_bus_wdata,
        o_rdataa  => bus_rdata,
        o_rvalida => rvalid,

        i_addrb   => cacheline_axi,
        i_enb     => cache_en,
        i_wenb    => cache_wen,
        i_wdatab  => i_m_axi_rdata,
        o_rdatab  => open,
        o_rvalidb => open
    );

    eMetadataBram : entity rktcpu.DualPortBram
    generic map (
        cAddressWidth_b => cCachelineAddrWidth_b,
        cMaxAddress     => cNumCachelines - 1,
        cDataWidth_b    => cMetaDataWidth_b
    ) port map (
        i_clk => i_clk,

        i_addra  => cacheline,
        i_ena    => i_bus_ren,
        i_wena   => '0', 
        i_wdataa => (others => '0'),
        o_rdataa => metadata,

        i_addrb  => addrb,
        i_enb    => enb,
        i_wenb   => wenb,
        i_wdatab => metadata_b,
        o_rdatab => open
    );

    -- It's a cache miss if the data is not valid or the data that is valid is for the wrong address.
    miss <= bool2bit(metadata(cValid) = '0') or 
        (metadata(cValid) and bool2bit(memaddr_reg /= metadata(cMemAddrWidth_b - 1 downto 0)));

    cacheline    <= i_bus_addr(cCachelineAddrWidth_b - 1 downto 0);
    memaddr      <= i_bus_addr(31 downto cCachelineAddrWidth_b);
    o_bus_rvalid <= (rvalid and not miss) or cache_en;
    o_bus_rdata  <= i_m_axi_rdata when cache_en else bus_rdata;

    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        -- In the IDLE state, we're waiting until a dirty bit or a miss occurs.
                        -- Keep the enb and wenb signals cleared until a dirty bit event happens.
                        enb   <= '0';
                        wenb  <= '0';

                        -- Maintain copies of the input signals since there is no guarantee they will
                        -- stay set from cycle to cycle.
                        ren_reg       <= i_bus_ren;
                        wen_reg       <= i_bus_wen;
                        memaddr_reg   <= memaddr;
                        cacheline_reg <= cacheline;

                        -- If we made a read request (ren) and missed, we need to follow the following.
                        if ((ren_reg and miss) = '1') then
                            -- We need to preserve the old address which we get from combining the 
                            -- bottom N bits from the metadata and the last cacheline.
                            old_addr <= metadata(cMemAddrWidth_b - 1 downto 0) & cacheline_reg;

                            -- We need to preserve the old data in case we have any data to store
                            -- i.e. valid and dirty bits are set.
                            old_data <= rdata;

                            -- We need to preserve the new address so that when we do a CACHE_FETCH
                            -- we get the latest data from this address.
                            new_addr <= memaddr_reg & cacheline_reg;

                            -- If we've got our valid and dirty bits set, we need to CACHE_FLUSH then
                            -- CACHE_FETCH. Otherwise, we can skip the fetch.
                            if ((metadata(cValid) and metadata_b(cDirty)) = '1') then
                                state <= CACHE_FLUSH;
                            else
                                state <= CACHE_FETCH;
                            end if;
                        elsif ((ren_reg and not miss and (wen_reg(0) or wen_reg(1) or wen_reg(2) or wen_reg(3))) = '1') then
                            -- Or, when we don't miss but are actually writing new data, we need to update the
                            -- dirty bit for the cacheline to make sure the cache knows to flush this when
                            -- we next update.
                            metadata_b         <= metadata;
                            metadata_b(cDirty) <= '1';

                            addrb <= cacheline_reg;
                            enb   <= '1';
                            wenb  <= '1';
                        end if;
                    
                    when CACHE_FLUSH =>
                        -- Since we're operating with an AXI interface, we need to start a 
                        -- write transaction by transferring on the AXI write address (AW) and
                        -- the AXI write data (W) channels. These will go high simultaneously,
                        -- but since the AXI spec allows for a delay between AW and W transfers in
                        -- a basic write transaction, we're allowing them to complete at different times.
                        if (i_m_axi_awready = '1') then
                            awready         <= '1';
                            o_m_axi_awvalid <= '0';
                        elsif (awready = '0') then
                            o_m_axi_awaddr  <= old_addr;
                            o_m_axi_awvalid <= '1';
                        end if;

                        -- Warning, this may cause the WDATA to be accepted before the AWADDR, which
                        -- may cause bugs.
                        if (i_m_axi_wready = '1') then
                            wready         <= '1';
                            o_m_axi_wvalid <= '0';
                        elsif (wready = '0') then
                            o_m_axi_wdata  <= old_data;
                            o_m_axi_wvalid <= '1';
                            o_m_axi_wstrb  <= "1111";
                        end if;

                        -- If we get both transfers complete, then we're ready to go to the response state.
                        if ((awready and wready) or (i_m_axi_awready and i_m_axi_wready) = '1') then
                            wready  <= '0';
                            awready <= '0';
                            state   <= CACHE_FLUSH_RESP;
                        end if;

                    when CACHE_FLUSH_RESP =>
                        -- Read the bresp and then go to cache fetch.
                        o_m_axi_bready <= '1';
                        if (i_m_axi_bvalid = '1') then
                            resp           <= i_m_axi_bresp;
                            o_m_axi_bready <= '0';
                            state          <= CACHE_FETCH;
                        end if;
                    
                    when CACHE_FETCH =>
                        -- We're fetching information from the provided address,
                        -- which means we need to initiate a transaction on the address 
                        -- read (AR) side.
                        if (i_m_axi_arready = '1') then
                            o_m_axi_arvalid <= '0';
                            state <= CACHE_FETCH_RESP;
                        else
                            o_m_axi_araddr  <= new_addr;
                            o_m_axi_arvalid <= '1';
                        end if;

                    when CACHE_FETCH_RESP =>
                        -- Now that we have a minute, we need to quickly reset the 
                        -- metadata for this cacheline while we wait for the 
                        -- AXI peripheral to respond.
                        if (update = '0') then
                            metadata_b <= "00" & memaddr_axi;

                            addrb <= cacheline_axi;
                            enb   <= '1';
                            wenb  <= '1';

                            update <= '1';
                        else
                            enb   <= '0';
                            wenb  <= '0';
                        end if;

                        -- Once the AXI peripheral responds, the data should 
                        -- go directly into the cache without further 
                        -- intervention from this state machine, so we can go back to idle.
                        o_m_axi_rready <= '1';
                        if (i_m_axi_rvalid = '1') then
                            resp           <= i_m_axi_rresp;
                            o_m_axi_rready <= '0';
                            state          <= IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process StateMachine;
    
end architecture rtl;