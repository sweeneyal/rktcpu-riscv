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

library scrv;
    use scrv.RiscVDefinitions.all;
    use scrv.DataPathEntities.all;

entity tb_MemAccessUnit is
    generic (runner_cfg : string);
end entity tb_MemAccessUnit;

architecture tb of tb_MemAccessUnit is
    signal clk    : std_logic;
    signal opcode : std_logic_vector(6 downto 0);
    signal opA    : std_logic_vector(31 downto 0);
    signal itype  : std_logic_vector(11 downto 0);
    signal stype  : std_logic_vector(11 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal addr   : std_logic_vector(31 downto 0);
    signal men    : std_logic;
    signal mwen   : std_logic_vector(3 downto 0);
    signal rvalid : std_logic;
    signal rdata  : std_logic_vector(31 downto 0);
    signal data   : std_logic_vector(31 downto 0);
    signal ldone  : std_logic;
    signal sdone  : std_logic;
    signal msaln  : std_logic;

    signal wdata : std_logic_vector(31 downto 0);

    procedure emulate_memory_store (
        variable memory : out std_logic_matrix_t;
        signal address  : in std_logic_vector(31 downto 0);
        signal en       : in std_logic;
        signal wen      : in std_logic_vector(3 downto 0);
        signal wdata_s  : in std_logic_vector(31 downto 0)
    ) is
        variable addr_v : natural;
    begin
        addr_v := to_natural(address);
        if (en = '1') then
            for ii in 0 to 3 loop
                if (wen(ii) = '1') then
                    -- Problem is that this is allows a non-multiple of 4 addr to index the memory.
                    -- This is likely acceptable, as in a real implementation there would be an exception,
                    -- that then performs a system function that performs the unaligned memory access.
                    -- However, may be worth intrinsically supporting misaligned accesses.
                    memory(addr_v + ii) := wdata_s(8 * (ii + 1) - 1 downto 8 * ii);
                end if;
            end loop;
        end if;
    end procedure;

    function emulate_memory_load (
        memory  : std_logic_matrix_t;
        address : std_logic_vector(31 downto 0);
        en      : std_logic;
        wen     : std_logic_vector(3 downto 0)
    ) return std_logic_vector is
        variable rdata_v : std_logic_vector(31 downto 0);
        variable addr_v : natural;
    begin
        rdata_v  := to_slv(0, 32);
        addr_v := to_natural(address);
        if (en = '1') then
            for ii in 0 to 3 loop
                -- Problem is that this is allows a non-multiple of 4 addr to index the memory.
                -- This is likely acceptable, as in a real implementation there would be an exception,
                -- that then performs a system function that performs the unaligned memory access. Or
                -- we would intrinsically support misaligned accesses.
                rdata_v(8 * (ii + 1) - 1 downto 8 * ii) := memory(addr_v + ii);
            end loop;
        end if;
        return rdata_v;
    end function;
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : MemAccessUnit
    port map (
        i_clk    => clk,
        i_opcode => opcode,
        i_opA    => opA,
        i_itype  => itype,
        i_stype  => stype,
        i_funct3 => funct3,
        
        o_addr => addr,
        o_men  => men,
        o_mwen => mwen,

        i_rvalid => rvalid,
        i_rdata  => rdata,
        
        o_data  => data,
        o_ldone => ldone,
        o_sdone => sdone,
        o_msaln => msaln
    );

    Stimuli: process
        variable memory_emulator : std_logic_matrix_t(0 to 63)(7 downto 0);
        variable RandData        : RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_memory_store") then
                opcode <= cStoreOpcode;
                opA    <= to_slv(4, 32);
                itype  <= (others => '0');
                stype  <= to_slv(4, 12);
                funct3 <= "010";
                rvalid <= '0';
                rdata  <= (others => '0');
                wdata  <= RandData.RandSlv(x"00000000", x"FFFFFFFF");

                wait until rising_edge(clk);
                wait for 100 ps;
                check(addr  = std_logic_vector(s32_t(opA) + to_s32(stype)));
                check(mwen  = "1111");
                check(men   = '1');
                check(msaln = '0');
                emulate_memory_store(memory_emulator, addr, men, mwen, wdata);
            elsif run("t_memory_store_misaligned") then
                opcode <= cStoreOpcode;
                opA    <= to_slv(4, 32);
                itype  <= (others => '0');
                stype  <= to_slv(3, 12);
                funct3 <= "010";
                rvalid <= '0';
                rdata  <= (others => '0');
                wdata  <= RandData.RandSlv(x"00000000", x"FFFFFFFF");

                wait until rising_edge(clk);
                wait for 100 ps;
                check(addr  = std_logic_vector(s32_t(opA) + to_s32(stype)));
                report "Checking MWEN";
                check(mwen  = "1111");
                report "Checking MEN";
                check(men   = '1');
                report "Checking MSALN";
                check(msaln = '1');
                -- For our purposes, misaligned memory stores are abstracted to say that the 
                -- trap handler will go ahead and perform the load/store.
                -- Or, the hardware will go ahead and convert the misaligned access.
                emulate_memory_store(memory_emulator, addr, men, mwen, wdata);
            elsif run("t_memory_store_load") then
                opcode <= cStoreOpcode;
                opA    <= to_slv(4, 32);
                itype  <= (others => '0');
                stype  <= to_slv(4, 12);
                funct3 <= "010";
                rvalid <= '0';
                rdata  <= (others => '0');
                wdata  <= RandData.RandSlv(x"00000000", x"FFFFFFFF");

                wait until rising_edge(clk);
                wait for 100 ps;
                check(addr  = std_logic_vector(s32_t(opA) + to_s32(stype)));
                check(mwen  = "1111");
                check(men   = '1');
                check(msaln = '0');
                emulate_memory_store(memory_emulator, addr, men, mwen, wdata);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;