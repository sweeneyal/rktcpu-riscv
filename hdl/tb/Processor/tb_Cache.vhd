library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;
    use osvvm.RandomPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;
    use rktcpu.RiscVDefinitions.all;

library tb;
    use tb.RiscVTbTools.all;

entity tb_Cache is
    generic (
        runner_cfg : string
    );
end entity tb_Cache;

architecture tb of tb_Cache is
    signal clk_i      : std_logic := '0';
    signal resetn_i   : std_logic := '0';
    
    signal bus_addr_i   : std_logic_vector(31 downto 0) := (others => '0');
    signal bus_ren_i    : std_logic := '0';
    signal bus_wen_i    : std_logic_vector(3 downto 0) := (others => '0');
    signal bus_wdata_i  : std_logic_vector(31 downto 0) := (others => '0');
    signal bus_wready_o : std_logic := '0';
    signal bus_rdata_o  : std_logic_vector(31 downto 0) := (others => '0');
    signal bus_rvalid_o : std_logic := '0';

    signal m_axi_awaddr_o  : std_logic_vector(31 downto 0) := (others => '0');
    signal m_axi_awprot_o  : std_logic_vector(2 downto 0) := (others => '0');
    signal m_axi_awvalid_o : std_logic := '0';
    signal m_axi_awready_i : std_logic := '0';

    signal m_axi_wdata_o   : std_logic_vector(31 downto 0) := (others => '0');
    signal m_axi_wstrb_o   : std_logic_vector(3 downto 0) := (others => '0');
    signal m_axi_wvalid_o  : std_logic := '0';
    signal m_axi_wready_i  : std_logic := '0';

    signal m_axi_bresp_i   : std_logic_vector(1 downto 0) := "00";
    signal m_axi_bvalid_i  : std_logic := '0';
    signal m_axi_bready_o  : std_logic := '0';

    signal m_axi_araddr_o  : std_logic_vector(31 downto 0) := (others => '0');
    signal m_axi_arprot_o  : std_logic_vector(2 downto 0) := (others => '0');
    signal m_axi_arvalid_o : std_logic := '0';
    signal m_axi_arready_i : std_logic := '0';

    signal m_axi_rdata_i   : std_logic_vector(31 downto 0) := (others => '0');
    signal m_axi_rresp_i   : std_logic_vector(1 downto 0) := (others => '0');
    signal m_axi_rvalid_i  : std_logic := '0';
    signal m_axi_rready_o  : std_logic := '0';
begin
    
    CreateClock(clk=>clk_i, period=>5 ns);

    eDut : entity rktcpu.Cache
    generic map (
        cCacheSize_B => 1024
    ) port map (
        i_clk    => clk_i,
        i_resetn => resetn_i,

        i_bus_addr   => bus_addr_i,
        i_bus_ren    => bus_ren_i,
        i_bus_wen    => bus_wen_i,
        i_bus_wdata  => bus_wdata_i,
        o_bus_wready => bus_wready_o,
        o_bus_rdata  => bus_rdata_o,
        o_bus_rvalid => bus_rvalid_o,

        o_m_axi_awaddr  => m_axi_awaddr_o,
        o_m_axi_awprot  => m_axi_awprot_o,
        o_m_axi_awvalid => m_axi_awvalid_o,
        i_m_axi_awready => m_axi_awready_i,

        o_m_axi_wdata   => m_axi_wdata_o,
        o_m_axi_wstrb   => m_axi_wstrb_o,
        o_m_axi_wvalid  => m_axi_wvalid_o,
        i_m_axi_wready  => m_axi_wready_i,

        i_m_axi_bresp   => m_axi_bresp_i,
        i_m_axi_bvalid  => m_axi_bvalid_i,
        o_m_axi_bready  => m_axi_bready_o,

        o_m_axi_araddr  => m_axi_araddr_o,
        o_m_axi_arprot  => m_axi_arprot_o,
        o_m_axi_arvalid => m_axi_arvalid_o,
        i_m_axi_arready => m_axi_arready_i,

        i_m_axi_rdata   => m_axi_rdata_i,
        i_m_axi_rresp   => m_axi_rresp_i,
        i_m_axi_rvalid  => m_axi_rvalid_i,
        o_m_axi_rready  => m_axi_rready_o
    );

    eAxiRam : entity tb.RandomAxiRam
    generic map (
        cVerboseMode => true
    )
    port map (
        i_clk    => clk_i,
        i_resetn => resetn_i,

        i_s_axi_awaddr  => m_axi_awaddr_o,
        i_s_axi_awprot  => m_axi_awprot_o,
        i_s_axi_awvalid => m_axi_awvalid_o,
        o_s_axi_awready => m_axi_awready_i,

        i_s_axi_wdata   => m_axi_wdata_o,
        i_s_axi_wstrb   => m_axi_wstrb_o,
        i_s_axi_wvalid  => m_axi_wvalid_o,
        o_s_axi_wready  => m_axi_wready_i,

        o_s_axi_bresp   => m_axi_bresp_i,
        o_s_axi_bvalid  => m_axi_bvalid_i,
        i_s_axi_bready  => m_axi_bready_o,

        i_s_axi_araddr  => m_axi_araddr_o,
        i_s_axi_arprot  => m_axi_arprot_o,
        i_s_axi_arvalid => m_axi_arvalid_o,
        o_s_axi_arready => m_axi_arready_i,

        o_s_axi_rdata   => m_axi_rdata_i,
        o_s_axi_rresp   => m_axi_rresp_i,
        o_s_axi_rvalid  => m_axi_rvalid_i,
        i_s_axi_rready  => m_axi_rready_o
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_simple") then
                resetn_i <= '0';
                wait until rising_edge(clk_i);
                wait for 100 ps;

                resetn_i <= '1';
                report "Verify that we can write unopposed to an empty cache.";
                for ii in 0 to 255 loop
                    bus_addr_i  <= to_slv(4 * ii, 32);
                    bus_ren_i   <= '1';
                    bus_wen_i   <= "1111";
                    bus_wdata_i <= to_slv(4 * ii, 32);

                    wait until rising_edge(clk_i);
                    wait for 100 ps;

                    check(bus_rvalid_o = '1');
                end loop;

                report "Verify that we can read unopposed from a dirty cache.";
                for ii in 0 to 255 loop
                    bus_addr_i  <= to_slv(4 * ii, 32);
                    bus_ren_i   <= '1';
                    bus_wen_i   <= "0000";
                    bus_wdata_i <= to_slv(4 * ii, 32);

                    wait until rising_edge(clk_i);
                    wait for 100 ps;

                    check(bus_rvalid_o = '1');
                    check(bus_rdata_o = to_slv(4 * ii, 32));
                end loop;

                report "Verify that when we write to a dirty cache, we eventually get a response.";
                for ii in 256 to 511 loop
                    bus_addr_i  <= to_slv(4 * ii, 32);
                    bus_ren_i   <= '1';
                    bus_wen_i   <= "1111";
                    bus_wdata_i <= to_slv(4 * ii, 32);

                    wait until rising_edge(clk_i);
                    wait for 100 ps;

                    wait until (bus_rvalid_o = '1');
                end loop;

                report "Verify that we can still read unopposed from a dirty cache.";
                for ii in 256 to 511 loop
                    bus_addr_i  <= to_slv(4 * ii, 32);
                    bus_ren_i   <= '1';
                    bus_wen_i   <= "0000";
                    bus_wdata_i <= to_slv(4 * ii, 32);

                    wait until rising_edge(clk_i);
                    wait for 100 ps;

                    check(bus_rvalid_o = '1');
                    check(bus_rdata_o = to_slv(4 * ii, 32));
                end loop;

                report "Verify that we can read from a dirty cache that updates.";
                for ii in 0 to 511 loop
                    bus_addr_i  <= to_slv(4 * ii, 32);
                    bus_ren_i   <= '1';
                    bus_wen_i   <= "0000";
                    bus_wdata_i <= to_slv(4 * ii, 32);

                    wait until rising_edge(clk_i);
                    wait for 100 ps;

                    report "Test " & integer'image(ii);
                    wait until (bus_rvalid_o = '1');
                    check(bus_rdata_o = to_slv(4 * ii, 32), 
                        "Expected: " & to_hstring(to_slv(4 * ii, 32)) & " Got: " & to_hstring(bus_rdata_o));
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;

    test_runner_watchdog(runner, 2 ms);
    
end architecture tb;