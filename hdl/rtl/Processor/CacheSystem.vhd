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

entity CacheSystem is
    generic (
        cIMemRegion : region_t := (x"00000000", x"000FFFFF");
        cDMemRegion : region_t := (x"00100000", x"001FFFFF")
    ); 
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- Internal bus side to allow CPU to bypass caches if necessary
        i_instr_addr   : in std_logic_vector(31 downto 0);
        i_instr_ren    : in std_logic;
        i_instr_wen    : in std_logic_vector(3 downto 0);
        i_instr_wdata  : in std_logic_vector(31 downto 0);
        o_instr_wready : out std_logic;
        o_instr_rdata  : out std_logic_vector(31 downto 0);
        o_instr_rvalid : out std_logic;

        i_data_addr   : in std_logic_vector(31 downto 0);
        i_data_ren    : in std_logic;
        i_data_wen    : in std_logic_vector(3 downto 0);
        i_data_wdata  : in std_logic_vector(31 downto 0);
        o_data_wready : out std_logic;
        o_data_rdata  : out std_logic_vector(31 downto 0);
        o_data_rvalid : out std_logic;

        -- Axi4 Lite interface
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
end entity CacheSystem;

architecture rtl of CacheSystem is
    
begin
    
    -- eDcache : entity rktcpu.Cache
    -- generic map (

    -- ) port map (

    -- );

    -- eIcache : entity rktcpu.Cache
    -- generic map (

    -- ) port map (

    -- );

    -- eAxiArbiter : entity rktcpu.Arbiter
    -- generic map (

    -- ) port map (

    -- );
    
end architecture rtl;