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
        address : std_logic_vector(31 downto 0);
        data    : std_logic_vector(31 downto 0);
        ptr     : memory_address_ptr_t;
    end record memory_address_t;
begin
    
    InternalTestStructure: process(i_clk)
        variable memory_ptr     : memory_address_ptr_t;
        variable old_memory_ptr : memory_address_ptr_t;
        variable RandData       : RandomPType;
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                -- definitely delete history, 
                -- would be the most repeatable, though we'd need to restart with the seed.
            else
                if (i_data_ren = '1') then
                    if (i_data_wen = "0001") then -- Fix this, this is a terrible implementation
                        if (memory_ptr = null) then
                            memory_ptr := 
                                new memory_address_t'(
                                    address=>i_data_addr, 
                                    data=>i_data_wdata, 
                                    ptr=>null);
                        else
                            old_memory_ptr := memory_ptr;
                            while (memory_ptr.address /= i_data_addr and memory_ptr.ptr /= null) loop
                                memory_ptr := memory_ptr.ptr;
                            end loop;
    
                            if (memory_ptr.address = i_data_addr) then
                                memory_ptr.data := i_data_wdata;
                            elsif (memory_ptr.ptr /= null) then
                                memory_ptr.ptr := 
                                    new memory_address_t'(
                                        address=>i_data_addr, 
                                        data=>i_data_wdata, 
                                        ptr=>null);
                            end if;
                            memory_ptr := old_memory_ptr;
                        end if;
                        o_data_rdata  <= (others => '0');
                        o_data_rvalid <= '0';
                    else
                        if (memory_ptr = null) then
                            memory_ptr := 
                                new memory_address_t'(
                                    address=>i_data_addr, 
                                    data=>RandData.RandSlv(x"00000000", x"FFFFFFFF"), 
                                    ptr=>null);
                            o_data_rdata <= memory_ptr.data;
                            o_data_rvalid <= '1';
                        else
                            old_memory_ptr := memory_ptr;
                            while (memory_ptr.address /= i_data_addr and memory_ptr.ptr /= null) loop
                                memory_ptr := memory_ptr.ptr;
                            end loop;

                            if (memory_ptr.address = i_data_addr) then
                                o_data_rdata <= memory_ptr.data;
                            elsif (memory_ptr.ptr /= null) then
                                memory_ptr.ptr := 
                                    new memory_address_t'(
                                        address=>i_data_addr, 
                                        data=>RandData.RandSlv(x"00000000", x"FFFFFFFF"), 
                                        ptr=>null);
                                o_data_rdata <= memory_ptr.ptr.data;
                            end if;
                            o_data_rvalid <= '1';
                            memory_ptr := old_memory_ptr;
                        end if;
                    end if;
                else
                    o_data_rdata <= x"00000000";
                    o_data_rvalid <= '0';
                end if;
            end if;
        end if;
    end process InternalTestStructure;
    
end architecture rtl;