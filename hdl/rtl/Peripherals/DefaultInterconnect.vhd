library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity DefaultInterconnect is
    port (
        i_data_addr   : in std_logic_vector(31 downto 0);
        i_data_ren    : in std_logic;
        i_data_wen    : in std_logic_vector(3 downto 0);
        i_data_wdata  : in std_logic_vector(31 downto 0);
        o_data_rdata  : out std_logic_vector(31 downto 0);
        o_data_rvalid : out std_logic;

        o_bram_addr   : out std_logic_vector(12 downto 0);
        o_bram_ren    : out std_logic;
        o_bram_wen    : out std_logic_vector(3 downto 0);
        o_bram_wdata  : out std_logic_vector(31 downto 0);
        i_bram_rdata  : in std_logic_vector(31 downto 0);
        i_bram_rvalid : in std_logic;

        o_gpio_ren    : out std_logic;
        o_gpio_wen    : out std_logic_vector(3 downto 0);
        o_gpio_wdata  : out std_logic_vector(31 downto 0);
        i_gpio_rdata  : in std_logic_vector(31 downto 0);
        i_gpio_rvalid : in std_logic
    );
end entity DefaultInterconnect;

architecture rtl of DefaultInterconnect is
    signal data_addr_upper : std_logic_vector(18 downto 0) := (others => '0');
begin
    
    o_gpio_ren   <= bool2bit(i_data_addr = x"00010000");
    o_gpio_wen   <= i_data_wen;
    o_gpio_wdata <= i_data_wdata;

    o_bram_addr     <= i_data_addr(12 downto 0);
    data_addr_upper <= i_data_addr(31 downto 13);
    o_bram_ren      <= i_data_ren and bool2bit(to_natural(data_addr_upper) = 1);
    o_bram_wen      <= i_data_wen;
    o_bram_wdata    <= i_data_wdata;

    o_data_rdata  <= i_gpio_rdata when (i_data_addr = x"00010000") else i_bram_rdata;
    o_data_rvalid <= i_gpio_rvalid when (i_data_addr = x"00010000") else i_bram_rvalid;
    
    
end architecture rtl;