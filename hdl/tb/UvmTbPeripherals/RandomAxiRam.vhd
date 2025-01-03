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

library tb;
    use tb.RiscVTbTools.all;

entity RandomAxiRam is
    generic (
        cCheckUninitialized : boolean := true;
        cVerboseMode : boolean := false
    );
    port (
        i_clk         : in std_logic;
        i_resetn      : in std_logic;

        i_s_axi_awaddr  : in  std_logic_vector(31 downto 0);
        i_s_axi_awprot  : in  std_logic_vector(2 downto 0);
        i_s_axi_awvalid : in  std_logic;
        o_s_axi_awready : out std_logic;

        i_s_axi_wdata   : in std_logic_vector(31 downto 0);
        i_s_axi_wstrb   : in std_logic_vector(3 downto 0);
        i_s_axi_wvalid  : in std_logic;
        o_s_axi_wready  : out std_logic;

        o_s_axi_bresp   : out std_logic_vector(1 downto 0);
        o_s_axi_bvalid  : out std_logic;
        i_s_axi_bready  : in  std_logic;

        i_s_axi_araddr  : in  std_logic_vector(31 downto 0);
        i_s_axi_arprot  : in  std_logic_vector(2 downto 0);
        i_s_axi_arvalid : in  std_logic;
        o_s_axi_arready : out std_logic;

        o_s_axi_rdata   : out std_logic_vector(31 downto 0);
        o_s_axi_rresp   : out std_logic_vector(1 downto 0);
        o_s_axi_rvalid  : out std_logic;
        i_s_axi_rready  : in  std_logic
    );
end entity RandomAxiRam;

architecture rtl of RandomAxiRam is
    type memory_address_t;
    type memory_address_ptr_t is access memory_address_t;
    type memory_address_t is record
        address : std_logic_vector(31 downto 2);
        data    : std_logic_vector(31 downto 0);
        ptr     : memory_address_ptr_t;
    end record memory_address_t;

    procedure handle_aligned(
        variable memptr : inout memory_address_ptr_t;
        signal i_addr   : in std_logic_vector(31 downto 2);
        signal i_wen    : in std_logic_vector(3 downto 0);
        signal i_wdata  : in std_logic_vector(31 downto 0);
        signal o_rdata  : out std_logic_vector(31 downto 0)
    ) is
        -- Temporary rdata
        variable trdata     : std_logic_vector(31 downto 0);
        variable readonly   : boolean;
        variable old_memptr : memory_address_ptr_t;
    begin
        if (cVerboseMode) then
            if (any(i_wen) = '1') then
                report "WRITE tb.AXI_RAM[" & to_hstring(i_addr) & "]=" & to_hstring(i_wdata);
            end if;
        end if;
        if (memptr = null) then
            -- We're creating the first memory address.
            readonly := true;
            -- Iterate over a variable and write the data to it, to be used in the memory creation later.
            for ii in 0 to 3 loop
                if (i_wen(ii) = '1') then
                    trdata(8 * (ii + 1) - 1 downto 8 * ii) := i_wdata(8 * (ii + 1) - 1 downto 8 * ii);
                    readonly := false;
                else
                    trdata(8 * (ii + 1) - 1 downto 8 * ii) := x"00";
                end if;
            end loop;

            -- If we're making sure we dont read uninitialized memory addresses, then assert.
            assert (readonly and cCheckUninitialized) = false report "Uninitialized read detected.";

            -- Create the memory address we're interested in.
            memptr := 
                new memory_address_t'(
                    address=>i_addr(31 downto 2), 
                    data=>trdata, 
                    ptr=>null);
        else
            -- We're iterating the linked list until we find either the address we're looking for
            -- or the end of the list.
            old_memptr := memptr;
            while (memptr.address /= i_addr 
                    and memptr.ptr /= null) loop
                memptr := memptr.ptr;
            end loop;
                
            if (memptr.address = i_addr) then
                -- We found the address, now read it
                readonly := true;
                -- Iterate over the data lanes, writing the result only when wen(ii) = '1';
                for ii in 0 to 3 loop
                    if (i_wen(ii) = '1') then
                        memptr.data(8 * (ii + 1) - 1 downto 8 * ii) := i_wdata(8 * (ii + 1) - 1 downto 8 * ii);
                        readonly := false;
                    end if;
                end loop;
                if (cVerboseMode) then
                    if (any(i_wen) = '0') then
                        report "READ tb.AXI_RAM[" & to_hstring(i_addr) & "]=" & to_hstring(memptr.data);
                    end if;
                end if;

                -- Make sure we also write the rdata out as well, no matter what.
                o_rdata  <= memptr.data;

            elsif (memptr.ptr = null) then
                readonly := true;
                -- Iterate over a variable and write the data to it, to be used in the memory creation later.
                for ii in 0 to 3 loop
                    if (i_wen(ii) = '1') then
                        trdata(8 * (ii + 1) - 1 downto 8 * ii) := i_wdata(8 * (ii + 1) - 1 downto 8 * ii);
                        readonly := false;
                    else
                        trdata(8 * (ii + 1) - 1 downto 8 * ii) := x"00";
                    end if;
                end loop;

                --- If we're making sure we dont read uninitialized memory addresses, then assert.
                assert (readonly and cCheckUninitialized) = false report "Uninitialized read detected on address " & to_hstring(i_addr) & ".";

                -- Create the memory address we're interested in.
                memptr.ptr := 
                    new memory_address_t'(
                        address=>i_addr, 
                        data=>trdata, 
                        ptr=>null);
            end if;
            memptr := old_memptr;
        end if;
    end procedure;

    type state_t is (IDLE, WRITE_SEQUENCE, WRITE_RESPONSE, READ_SEQUENCE);
    signal state : state_t := IDLE;
    signal awaddr : std_logic_vector(31 downto 0) := (others => '0');
    signal araddr : std_logic_vector(31 downto 0) := (others => '0');
    signal wen_c  : std_logic_vector(3 downto 0) := (others => '0');
begin
    
    InternalTestStructure: process(i_clk)
        variable memory_ptr     : memory_address_ptr_t;
        variable wdata          : std_logic_vector(31 downto 0);
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                -- definitely delete history, 
                -- would be the most repeatable, though we'd need to restart with the seed.
            else
                case state is
                    when IDLE =>
                        o_s_axi_rvalid <= '0';
                        if (i_s_axi_awvalid = '1') then
                            state  <= WRITE_SEQUENCE;
                            awaddr <= i_s_axi_awaddr;
                            o_s_axi_awready <= '1';
                        elsif (i_s_axi_arvalid = '1') then
                            state  <= READ_SEQUENCE;
                            araddr <= i_s_axi_araddr;
                            o_s_axi_arready <= '1';
                        end if;

                    when WRITE_SEQUENCE =>
                        o_s_axi_awready <= '0';
                        if (i_s_axi_wvalid = '1') then
                            handle_aligned(
                                memptr   => memory_ptr,
                                i_addr   => awaddr(31 downto 2),
                                i_wen    => i_s_axi_wstrb,
                                i_wdata  => i_s_axi_wdata,
                                o_rdata  => o_s_axi_rdata
                            );
                            
                            o_s_axi_wready <= '1';
                            o_s_axi_bresp  <= "00";
                            o_s_axi_bvalid <= '1';

                            state <= WRITE_RESPONSE;
                        end if;
                
                    when WRITE_RESPONSE =>
                        o_s_axi_wready <= '0';
                        if (i_s_axi_bready = '1') then
                            o_s_axi_bvalid <= '0';
                            state          <= IDLE;
                        end if;

                    when READ_SEQUENCE =>
                        o_s_axi_arready <= '0';
                        handle_aligned(
                            memptr   => memory_ptr,
                            i_addr   => araddr(31 downto 2),
                            i_wen    => wen_c,
                            i_wdata  => i_s_axi_wdata,
                            o_rdata  => o_s_axi_rdata
                        );
                        o_s_axi_rvalid <= '1';
                        o_s_axi_rresp  <= "00";
                        if (i_s_axi_rready = '1') then
                            state <= IDLE;
                            o_s_axi_rvalid <= '0';
                        end if;
                        
                end case;
            end if;
        end if;
    end process InternalTestStructure;
    
end architecture rtl;