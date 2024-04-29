library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonTypes.all;
    use universal.CommonFunctions.all;

package Peripherals is

component RamInterface is
    port (
        i_clk : in std_logic;
        i_resetn : in std_logic;

        -- Data Bus Signals
        i_data_addr   : in std_logic_vector(31 downto 0);
        i_data_ren    : in std_logic;
        i_data_wen    : in std_logic_vector(3 downto 0);
        i_data_wdata  : in std_logic_vector(31 downto 0);
        o_data_rdata  : out std_logic_vector(31 downto 0);
        o_data_rvalid : out std_logic;

        -- AXI4 Bus Interface
        -- Identification tag for a write transaction
        o_axi4_awid : out std_logic;
        -- Address of the first transfer in a write transaction
        o_axi4_awaddr : out std_logic_vector(27 downto 0);
        -- Exact number of data transfers in a write transaction
        o_axi4_awlen : out std_logic_vector(87 downto 0);
        -- Number of bytes in each data transfer in a write transaction
        o_axi4_awsize : out std_logic_vector(2 downto 0);
        -- Burst type, indicates how address changes between each transfer
        o_axi4_awburst : out std_logic_vector(1 downto 0);
        -- Provides information about the atomic characteristics of a write transaction
        o_axi4_awlock : out std_logic;
        -- Indicates how a write transaction is required to progress through a system
        o_axi4_awcache : out std_logic_vector(3 downto 0);
        -- Protection attributes of a write transaction: priviledge, security level, and access type
        o_axi4_awprot : out std_logic_vector(2 downto 0);
        -- Quality of Service identifier for a write transaction
        o_axi4_awqos : out std_logic_vector(3 downto 0);
        -- Region indicator for a write transaction
        o_axi4_awregion : out std_logic; -- Unused on MIG
        -- User defined extension for the write address channel.
        o_axi4_awuser : out std_logic; -- Unused on MIG
        -- Indicates that the write address channel signals are valid.
        o_axi4_awvalid : out std_logic;
        -- Indicates that a transfer on the write address channel can be accepted.
        i_axi4_awready : in std_logic;

        -- Write data
        o_axi4_wdata : out std_logic_vector(127 downto 0);
        -- Write strobes, indicate which byte lanes hold valid data
        o_axi4_wstrb : out std_logic_vector(15 downto 0);
        -- Indicates whether this is the last data transfer in a write transaction
        o_axi4_wlast : out std_logic;
        -- User defined extension for the write data channel
        o_axi4_wuser : out std_logic; -- Unused on MIG
        -- Indicates that the write data channel signals are valid
        o_axi4_wvalid : out std_logic;
        -- Indicates that a transfer on the write data channel can be accepted.
        i_axi4_wready : in std_logic;

        -- Identification tag for a write response
        i_axi4_bid : in std_logic;
        -- Write response, indicates the status of a write transaction
        i_axi4_bresp : in std_logic_vector(1 downto 0);
        -- User defined extension for the write response channel.
        i_axi4_buser : in std_logic; -- Unused on MIG
        -- Indicates that the write response channel signals are valid.
        i_axi4_bvalid : in std_logic;
        -- Indicates that a transfer on the write response channel can be accepted.
        o_axi4_bready : out std_logic;

        -- Identification tag for a read transaction
        o_axi4_arid : out std_logic;
        -- Address of the first transfer in a read transaction
        o_axi4_araddr : out std_logic_vector(27 downto 0);
        -- Exact number of data transfers in a read transaction
        o_axi4_arlen : out std_logic_vector(7 downto 0);
        -- Number of bytes in each data transfer in a read transaction
        o_axi4_arsize : out std_logic_vector(2 downto 0);
        -- Burst type, indicates how address changes btw each transfer in a read transaction
        o_axi4_arburst : out std_logic_vector(1 downto 0);
        -- Provides information about the atomic characteristics of a read transaction
        o_axi4_arlock : out std_logic;
        -- Indicates how a read transaction is required to procress through a system
        o_axi4_arcache : out std_logic_vector(3 downto 0);
        -- Protectin attributes of a read transaction: privilege, security level, and acces type
        o_axi4_arprot : out std_logic_vector(2 downto 0);
        -- Quality of Service identifier for a read transaction
        o_axi4_arqos : out std_logic_vector(3 downto 0);
        -- Region indicator for a read transaction
        o_axi4_arregion : out std_logic; -- Unused on MIG
        -- User defined extension for the read address channel
        o_axi4_aruser : out std_logic; -- Unused on MIG
        -- Indicates that the read address channel signals are valid
        o_axi4_arvalid : out std_logic;
        -- Indicates that a transfer n the read address channel can be accepted.
        i_axi4_arready : in std_logic;

        -- Identification tag for read data and response
        i_axi4_rid : in std_logic;
        -- Read data
        i_axi4_rdata : in std_logic_vector(127 downto 0);
        -- Read response, indicates the status of a read transfer
        i_axi4_rresp : in std_logic_vector(1 downto 0);
        -- Indicates whether this is the alst data transfer in a read transaction
        i_axi4_rlast : in std_logic;
        -- User defined extension for the read data channel
        i_axi4_ruser : in std_logic; -- Unused on MIG
        -- INdicates that the read data channel signals are valid
        i_axi4_rvalid : in std_logic;
        -- Indicates that a transfer on the read data channels can be accepted
        o_axi4_rready : out std_logic

    );
end component RamInterface;

end package Peripherals;