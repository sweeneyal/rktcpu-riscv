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

entity RandomRam is
    generic (
        cCheckUninitialized : boolean := true
    );
    port (
        i_clk         : in std_logic;
        i_resetn      : in std_logic;
        i_data_addr   : in std_logic_vector(31 downto 0);
        i_data_ren    : in std_logic;
        i_data_wen    : in std_logic_vector(3 downto 0);
        i_data_wdata  : in std_logic_vector(31 downto 0);
        o_data_rdata  : out std_logic_vector(31 downto 0);
        o_data_rvalid : out std_logic
    );
end entity RandomRam;

architecture rtl of RandomRam is
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
                assert (readonly and cCheckUninitialized) = false report "Uninitialized read detected.";

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
                if (i_data_ren = '1') then
                    handle_aligned(
                        memptr   => memory_ptr,
                        i_addr   => i_data_addr(31 downto 2),
                        i_wen    => i_data_wen,
                        i_wdata  => i_data_wdata,
                        o_rdata  => o_data_rdata
                    );
                end if;
                o_data_rvalid <= i_data_ren;
            end if;
        end if;
    end process InternalTestStructure;
    
end architecture rtl;