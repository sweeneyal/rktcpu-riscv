library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity AxiArbiter is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- AXI Port 1
        i_mp1_axi_awaddr  : in  std_logic_vector(31 downto 0);
        i_mp1_axi_awprot  : in  std_logic_vector(2 downto 0);
        i_mp1_axi_awvalid : in  std_logic;
        o_mp1_axi_awready : out std_logic;

        i_mp1_axi_wdata   : in  std_logic_vector(31 downto 0);
        i_mp1_axi_wstrb   : in  std_logic_vector(3 downto 0);
        i_mp1_axi_wvalid  : in  std_logic;
        o_mp1_axi_wready  : out std_logic;

        i_mp1_axi_bresp   : in  std_logic_vector(1 downto 0);
        i_mp1_axi_bvalid  : in  std_logic;
        o_mp1_axi_bready  : out std_logic;

        i_mp1_axi_araddr  : in  std_logic_vector(31 downto 0);
        i_mp1_axi_arprot  : in  std_logic_vector(2 downto 0);
        i_mp1_axi_arvalid : in  std_logic;
        o_mp1_axi_arready : out std_logic;

        o_mp1_axi_rdata   : out std_logic_vector(31 downto 0);
        o_mp1_axi_rresp   : out std_logic_vector(1 downto 0);
        o_mp1_axi_rvalid  : out std_logic;
        i_mp1_axi_rready  : in  std_logic;

        -- AXI Port 2
        i_mp2_axi_awaddr  : in  std_logic_vector(31 downto 0);
        i_mp2_axi_awprot  : in  std_logic_vector(2 downto 0);
        i_mp2_axi_awvalid : in  std_logic;
        o_mp2_axi_awready : out std_logic;

        i_mp2_axi_wdata   : in  std_logic_vector(31 downto 0);
        i_mp2_axi_wstrb   : in  std_logic_vector(3 downto 0);
        i_mp2_axi_wvalid  : in  std_logic;
        o_mp2_axi_wready  : out std_logic;

        o_mp2_axi_bresp   : out std_logic_vector(1 downto 0);
        o_mp2_axi_bvalid  : out std_logic;
        i_mp2_axi_bready  : in  std_logic;

        i_mp2_axi_araddr  : in  std_logic_vector(31 downto 0);
        i_mp2_axi_arprot  : in  std_logic_vector(2 downto 0);
        i_mp2_axi_arvalid : in  std_logic;
        o_mp2_axi_arready : out std_logic;

        o_mp2_axi_rdata   : out std_logic_vector(31 downto 0);
        o_mp2_axi_rresp   : out std_logic_vector(1 downto 0);
        o_mp2_axi_rvalid  : out std_logic;
        i_mp2_axi_rready  : in  std_logic;

        -- Arbited AXI Port
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
end entity AxiArbiter;