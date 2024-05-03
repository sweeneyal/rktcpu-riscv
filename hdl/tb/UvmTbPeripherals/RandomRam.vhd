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
        cCheckUninitialized : boolean := false
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

    function check_alignment(addr_bits : std_logic_vector(1 downto 0); wen : std_logic_vector(3 downto 0)) return boolean is
    begin
        case addr_bits is
            -- No matter what, if addr_bits is word aligned, we're good.
            when "00" =>
                return true;

            when "01" | "10" =>
                -- We can only have normal alignment for byte and halfword writes/reads.
                case wen is
                    when "0001" | "0011" =>
                        return true;
                    when others =>
                        -- Inherently considering 3/4 word writes unsanitary.
                        return false;
                end case;
        
            when "11" =>
                -- We can only have normal alignment for byte writes/reads.
                case wen is
                    when "0001" =>
                        return true;
                    when others =>
                        -- Inherently considering 3/4 word writes unsanitary.
                        return false;
                end case;

            when others =>
                -- Anything else, jail.
                return false;
        end case;
    end function;

    procedure handle_aligned(
        variable memptr : inout memory_address_ptr_t;
        signal i_addr   : in std_logic_vector(31 downto 2);
        signal i_wen    : in std_logic_vector(3 downto 0);
        signal i_wdata  : in std_logic_vector(31 downto 0);
        signal o_rdata  : out std_logic_vector(31 downto 0);
        signal o_rvalid : out std_logic
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
            assert (not readonly) or (not cCheckUninitialized) report "Uninitialized read detected.";

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
                -- Only declare the data as valid if only a read occurred.
                o_rvalid <= bool2bit(readonly);

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

                -- If we're making sure we dont read uninitialized memory addresses, then assert.
                assert (not readonly) or (not cCheckUninitialized) report "Uninitialized read detected.";

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

    procedure handle_unaligned(
        variable memptr : inout memory_address_ptr_t;
        signal i_addr   : in std_logic_vector(31 downto 0);
        signal i_wen    : in std_logic_vector(3 downto 0);
        signal i_wdata  : in std_logic_vector(31 downto 0);
        signal o_rdata  : out std_logic_vector(31 downto 0);
        signal o_rvalid : out std_logic
    ) is
        -- Temporary rdata
        variable trdata     : std_logic_vector(31 downto 0);
        variable wdata      : std_logic_vector(63 downto 0);
        variable readonly   : boolean;
        variable old_memptr : memory_address_ptr_t;
        variable addrs      : std_logic_matrix_t(0 to 1)(31 downto 2);
        variable wens       : std_logic_matrix_t(0 to 1)(3 downto 0);
        variable wdatas     : std_logic_matrix_t(0 to 1)(31 downto 0);
        variable addr0      : std_logic_vector(31 downto 2);
        variable addr1      : std_logic_vector(31 downto 2);
        variable wen_ext    : std_logic_vector(7 downto 0);
        variable wen0       : std_logic_vector(3 downto 0);
        variable wen1       : std_logic_vector(3 downto 0);
        variable offset     : natural;
    begin
        addrs(0) := i_addr(31 downto 2);
        addrs(1) := std_logic_vector(unsigned(i_addr(31 downto 2)) + to_unsigned(1, 30));

        offset := to_natural(i_addr(1 downto 0));

        wen_ext := std_logic_vector(shift_left(resize(unsigned(i_wen), 8), offset));
        wens(0) := wen_ext(3 downto 0);
        wens(1) := wen_ext(7 downto 4);

        wdata     := std_logic_vector(shift_left(resize(unsigned(i_wdata), 64), 8 * offset));
        wdatas(0) := wdata(31 downto 0);
        wdatas(1) := wdata(63 downto 32);

        if (memptr = null) then
            -- We're creating the first memory address.
            -- For unaligned operations, we're always accessing two addresses, which are i_addr and i_addr + 1
            -- Therefore, create one for the first address, then create one for the second address.
            readonly := true;
            
            for ii in 0 to 1 loop
                -- Iterate over a variable and write the data to it, to be used in the memory creation later.
                trdata := x"00000000";
                if ii = 0 then
                    for jj in offset to 3 loop
                        if (wens(ii)(jj) = '1') then
                            trdata(8 * (ii + 1) - 1 downto 8 * ii) := wdatas(ii)(8 * (jj + 1) - 1 downto 8 * jj);
                            readonly := false;
                        else
                            trdata(8 * (ii + 1) - 1 downto 8 * ii) := x"00";
                        end if;
                    end loop;

                    memptr := new memory_address_t'(
                        address=>addrs(ii), 
                        data=>trdata, 
                        ptr=>null);
                else
                    for jj in 0 to offset loop
                        if (wens(ii)(jj) = '1') then
                            trdata(8 * (ii + 1) - 1 downto 8 * ii) := wdatas(ii)(8 * (jj + 1) - 1 downto 8 * jj);
                            readonly := false;
                        else
                            trdata(8 * (ii + 1) - 1 downto 8 * ii) := x"00";
                        end if;
                    end loop;

                    memptr.ptr := new memory_address_t'(
                        address=>addrs(ii), 
                        data=>trdata, 
                        ptr=>null);
                end if;
            end loop;            

            -- If we're making sure we dont read uninitialized memory addresses, then assert.
            assert (not readonly) or (not cCheckUninitialized) report "Uninitialized read detected.";
            o_rdata <= x"00000000";
            o_rvalid <= bool2bit(readonly);
        else
            -- For unaligned operations, we're always accessing two addresses, which are i_addr and i_addr + 1
            -- Therefore, iterate this first for the first address and then iterate again for the second address.

            for ii in 0 to 1 loop
                -- We're iterating the linked list until we find either the address we're looking for
                -- or the end of the list.
                old_memptr := memptr;
                while (memptr.address /= addrs(ii) 
                        and memptr.ptr /= null) loop
                    memptr := memptr.ptr;
                end loop;
                    
                if (memptr.address = addrs(ii)) then
                    -- We found the address, now read it
                    readonly := true;
    
                    -- Iterate over a variable and write the data to it, to be used in the memory creation later.
                    trdata := memptr.data;
                    if (ii = 0) then
                        for jj in offset to 3 loop
                            if (wens(ii)(jj) = '1') then
                                trdata(8 * (ii + 1) - 1 downto 8 * ii) := wdatas(ii)(8 * (jj + 1) - 1 downto 8 * jj);
                                readonly := false;
                            end if;
                        end loop; 
                    else
                        for jj in 0 to offset loop
                            if (wens(ii)(jj) = '1') then
                                trdata(8 * (ii + 1) - 1 downto 8 * ii) := wdatas(ii)(8 * (jj + 1) - 1 downto 8 * jj);
                                readonly := false;
                            end if;
                        end loop;
                    end if;
                    memptr.data := trdata;
                    -- Make sure we also write the rdata out as well, no matter what.
                    o_rdata  <= memptr.data;
                    -- Only declare the data as valid if only a read occurred.
                    o_rvalid <= bool2bit(readonly);
    
                elsif (memptr.ptr = null) then
                    readonly := true;
                    
                    -- Create the memory address we're interested in.
                    memptr.ptr := 
                        new memory_address_t'(
                            address=>addrs(ii), 
                            data=>x"00000000", 
                            ptr=>null);

                    -- Iterate over a variable and write the data to it, to be used in the memory creation later.
                    trdata := memptr.data;
                    if (ii = 0) then
                        for jj in offset to 3 loop
                            if (wens(ii)(jj) = '1') then
                                trdata(8 * (ii + 1) - 1 downto 8 * ii) := wdatas(ii)(8 * (jj + 1) - 1 downto 8 * jj);
                                readonly := false;
                            end if;
                        end loop; 
                    else
                        for jj in 0 to offset loop
                            if (wens(ii)(jj) = '1') then
                                trdata(8 * (ii + 1) - 1 downto 8 * ii) := wdatas(ii)(8 * (jj + 1) - 1 downto 8 * jj);
                                readonly := false;
                            end if;
                        end loop;
                    end if;
                    memptr.data := trdata;
                    -- Make sure we also write the rdata out as well, no matter what.
                    o_rdata  <= memptr.data;
                    -- Only declare the data as valid if only a read occurred.
                    o_rvalid <= bool2bit(readonly);
    
                    -- If we're making sure we dont read uninitialized memory addresses, then assert.
                    assert (not readonly) or (not cCheckUninitialized) report "Uninitialized read detected.";
                end if;
                memptr := old_memptr;
            end loop;
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
                    if (check_alignment(i_data_addr(1 downto 0), i_data_wen)) then
                        handle_aligned(
                            memptr   => memory_ptr,
                            i_addr   => i_data_addr(31 downto 2),
                            i_wen    => i_data_wen,
                            i_wdata  => i_data_wdata,
                            o_rdata  => o_data_rdata,
                            o_rvalid => o_data_rvalid
                        );
                    else
                        handle_unaligned(
                            memptr   => memory_ptr,
                            i_addr   => i_data_addr,
                            i_wen    => i_data_wen,
                            i_wdata  => i_data_wdata,
                            o_rdata  => o_data_rdata,
                            o_rvalid => o_data_rvalid
                        );
                    end if;
                end if;
            end if;
        end if;
    end process InternalTestStructure;
    
end architecture rtl;