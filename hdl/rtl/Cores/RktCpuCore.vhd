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

entity RktCpuCore is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        i_extirpt : in std_logic;
        i_irpts   : in std_logic_vector(15 downto 0);

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
end entity RktCpuCore;

architecture rtl of RktCpuCore is
    
begin

    -- eRktCpu : entity rktcpu.RktCpuRiscV
    -- generic map (

    -- ) port map (
    --     i_clk    => i_clk,
    --     i_resetn => i_resetn,

    --     -- Add debug ports

    --     o_instr_addr   => instr_addr,
    --     o_instr_ren    => instr_ren,
    --     o_instr_wen    => instr_wen,
    --     o_instr_wdata  => instr_wdata,
    --     i_instr_wready => instr_wready,
    --     i_instr_rdata  => instr_rdata,
    --     i_instr_rvalid => instr_rvalid,

    --     o_data_addr   => data_addr,
    --     o_data_ren    => data_ren,
    --     o_data_wen    => data_wen,
    --     o_data_wdata  => data_wdata,
    --     i_data_wready => data_wready,
    --     i_data_rdata  => data_rdata,
    --     i_data_rvalid => data_rvalid,

    --     i_extirpt => i_extirpt,
    --     i_irpts   => i_irpts
    -- );

    -- eCacheSystem : entity rktcpu.CacheSystem
    -- generic map (
    --     cIMemRegion => (x"00000000", x"000FFFFF"),
    --     cDMemRegion => (x"00100000", x"001FFFFF")
    -- ) port map (
    --     i_clk         => i_clk,
    --     i_resetn      => i_resetn,

    --     -- Internal bus side to allow CPU to bypass caches if necessary
    --     i_instr_addr   => instr_addr,
    --     i_instr_ren    => instr_ren,
    --     i_instr_wen    => instr_wen,
    --     i_instr_wdata  => instr_wdata,
    --     o_instr_wready => instr_wready,
    --     o_instr_rdata  => instr_rdata,
    --     o_instr_rvalid => instr_rvalid,

    --     i_data_addr   => data_addr,
    --     i_data_ren    => data_ren,
    --     i_data_wen    => data_wen,
    --     i_data_wdata  => data_wdata,
    --     o_data_wready => data_wready,
    --     o_data_rdata  => data_rdata,
    --     o_data_rvalid => data_rvalid,

    --     -- Axi4 Lite interface
    --     o_m_axi_awaddr  => o_m_axi_awaddr,
    --     o_m_axi_awprot  => o_m_axi_awprot,
    --     o_m_axi_awvalid => o_m_axi_awvalid,
    --     i_m_axi_awready => i_m_axi_awready,

    --     o_m_axi_wdata   => o_m_axi_wdata,
    --     o_m_axi_wstrb   => o_m_axi_wstrb,
    --     o_m_axi_wvalid  => o_m_axi_wvalid,
    --     i_m_axi_wready  => i_m_axi_wready,

    --     i_m_axi_bresp   => i_m_axi_bresp,
    --     i_m_axi_bvalid  => i_m_axi_bvalid,
    --     o_m_axi_bready  => o_m_axi_bready,

    --     o_m_axi_araddr  => o_m_axi_araddr,
    --     o_m_axi_arprot  => o_m_axi_arprot,
    --     o_m_axi_arvalid => o_m_axi_arvalid,
    --     i_m_axi_arready => i_m_axi_arready,

    --     i_m_axi_rdata   => i_m_axi_rdata,
    --     i_m_axi_rresp   => i_m_axi_rresp,
    --     i_m_axi_rvalid  => i_m_axi_rvalid,
    --     o_m_axi_rready  => o_m_axi_rready
    -- );
    
end architecture rtl;