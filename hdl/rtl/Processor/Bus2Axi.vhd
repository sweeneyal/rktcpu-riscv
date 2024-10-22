library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity Bus2Axi is
    port (
        i_bus_addr   : in std_logic_vector(31 downto 0);
        i_bus_ren    : in std_logic;
        i_bus_wen    : in std_logic_vector(3 downto 0);
        i_bus_wdata  : in std_logic_vector(31 downto 0);
        o_bus_wready : out std_logic;
        o_bus_rdata  : out std_logic_vector(31 downto 0);
        o_bus_rvalid : out std_logic;

        -- AXI4-Lite Bus Interface
        -- Address of the first transfer in a write transaction
        o_axi4_awaddr : out std_logic_vector(31 downto 0);
        -- Protection attributes of a write transaction: priviledge, security level, and access type
        o_axi4_awprot : out std_logic_vector(2 downto 0);
        -- Indicates that the write address channel signals are valid.
        o_axi4_awvalid : out std_logic;
        -- Indicates that a transfer on the write address channel can be accepted.
        i_axi4_awready : in std_logic;

        -- Write data
        o_axi4_wdata : out std_logic_vector(31 downto 0);
        -- Write strobes, indicate which byte lanes hold valid data
        o_axi4_wstrb : out std_logic_vector(3 downto 0);
        -- Indicates that the write data channel signals are valid
        o_axi4_wvalid : out std_logic;
        -- Indicates that a transfer on the write data channel can be accepted.
        i_axi4_wready : in std_logic;

        -- Write response, indicates the status of a write transaction
        i_axi4_bresp : in std_logic_vector(1 downto 0);
        -- Indicates that the write response channel signals are valid.
        i_axi4_bvalid : in std_logic;
        -- Indicates that a transfer on the write response channel can be accepted.
        o_axi4_bready : out std_logic;

        -- Address of the first transfer in a read transaction
        o_axi4_araddr : out std_logic_vector(27 downto 0);
        -- Protection attributes of a read transaction: privilege, security level, and acces type
        o_axi4_arprot : out std_logic_vector(2 downto 0);
        -- Indicates that the read address channel signals are valid
        o_axi4_arvalid : out std_logic;
        -- Indicates that a transfer on the read address channel can be accepted.
        i_axi4_arready : in std_logic;

        i_axi4_rdata : in std_logic_vector(31 downto 0);
        -- Read response, indicates the status of a read transfer
        i_axi4_rresp : in std_logic_vector(1 downto 0);
        -- Indicates that the read data channel signals are valid
        i_axi4_rvalid : in std_logic;
        -- Indicates that a transfer on the read data channels can be accepted
        o_axi4_rready : out std_logic
    );
end entity Bus2Axi;

architecture rtl of Bus2Axi is
    signal wvalid : std_logic := '0';
    signal rvalid : std_logic := '0';
begin
    
    wvalid <= (i_bus_wen(3) or i_bus_wen(2) or i_bus_wen(1) or i_bus_wen(0)) and i_bus_ren;
    rvalid <= not (i_bus_wen(3) or i_bus_wen(2) or i_bus_wen(1) or i_bus_wen(0)) and i_bus_ren;

    o_axi4_awaddr  <= i_bus_addr;
    o_axi4_awvalid <= wvalid;
    
    o_axi4_wvalid <= wvalid;
    o_axi4_wstrb  <= i_bus_wen;
    o_axi4_wdata  <= i_bus_wdata;
    -- This could backfire.
    o_bus_wready  <= i_axi4_wready and i_axi4_awready;

    o_axi4_araddr  <= i_bus_addr;
    o_axi4_arvalid <= rvalid;

    o_axi4_rready <= rvalid;
    o_bus_rvalid  <= i_axi4_rvalid;
    o_bus_rdata   <= i_axi4_rdata;
    
end architecture rtl;