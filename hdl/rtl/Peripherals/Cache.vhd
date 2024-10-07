library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity Cache is
    generic (
        cAddressWidth_b : positive;
        cCacheSize_B    : positive;
        cMainBusWidth_B : positive;
        cDdrSize_B      : positive;
        cDdrBusWidth_B  : positive
    );
    port (
        i_clk        : in std_logic;
        i_resetn     : in std_logic;
        i_bus_addr   : in std_logic_vector(cAddressWidth_b - 1 downto 0);
        i_bus_en     : in std_logic;
        i_bus_wen    : in std_logic_vector(cMainBusWidth_B - 1 downto 0);
        i_bus_wdata  : in std_logic_vector(8 * cMainBusWidth_B - 1 downto 0);
        o_bus_rdata  : out std_logic_vector(8 * cMainBusWidth_B - 1 downto 0);
        o_bus_rvalid : out std_logic

        -- AXI4 bus definitions here.

    );
end entity Cache;

architecture rtl of Cache is
    -- See https://www.youtube.com/watch?v=8zc9B3dvTjc for explanation.
    constant cIntraCacheAddrWidth_b : natural := clog2(cDdrBusWidth_B);
    constant cCachelineSize_b       : natural := clog2(cCacheSize_B) - cIntraCacheAddrWidth_b;
    constant cMemoryAddrWidth_b     : natural := clog2(cDdrSize_B) - clog2(cCacheSize_B);

    function get_intracache(addr : std_logic_vector) return std_logic_vector is
    begin
        return addr(cIntraCacheAddrWidth_b - 1 downto 0);
    end function;

    function get_cacheline(addr : std_logic_vector) return std_logic_vector is
    begin
        return addr((cCachelineSize_b + cIntraCacheAddrWidth_b) - 1 
            downto cIntraCacheAddrWidth_b);
    end function;

    function get_memaddr(addr : std_logic_vector) return std_logic_vector is
    begin
        return addr((cMemoryAddrWidth_b + cCachelineSize_b + 
            cIntraCacheAddrWidth_b) - 1 
            downto (cCachelineSize_b + cIntraCacheAddrWidth_b));
    end function;

    signal intracache : std_logic_vector(cIntraCacheAddrWidth_b - 1 downto 0) := (others => '0');
    signal cacheline  : std_logic_vector(cCachelineSize_b - 1 downto 0) := (others => '0');
    signal memaddr    : std_logic_vector(cMemoryAddrWidth_b - 1 downto 0) := (others => '0');
begin
    
    intracache <= get_intracache(i_bus_addr);
    cacheline  <= get_cacheline(i_bus_addr);
    memaddr    <= get_memaddr(i_bus_addr);
    
end architecture rtl;