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

        o_cache_miss   : out std_logic;
        o_cache_addr   : out std_logic_vector(31 downto 0);
        i_cache_mready : in std_logic;

        i_cache_addr   : in std_logic_vector(31 downto 0);
        i_cache_ren    : in std_logic;
        i_cache_wen    : in std_logic_vector(3 downto 0);
        i_cache_wdata  : in std_logic_vector(31 downto 0);
        o_cache_wready : out std_logic;
        o_cache_rdata  : out std_logic_vector(31 downto 0);
        o_cache_rvalid : out std_logic
    );
end entity Cache;

architecture rtl of Cache is
    
begin
    
    
    
end architecture rtl;