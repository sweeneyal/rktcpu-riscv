library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

package CsrDefinitions is
    
    type machine_csr_t is record
        misa      : std_logic_vector(31 downto 0);
        mvendorid : std_logic_vector(31 downto 0);
        marchid   : std_logic_vector(31 downto 0);
        mimpid    : std_logic_vector(31 downto 0);
        mhartid   : std_logic_vector(31 downto 0);
        mstatus   : std_logic_vector(63 downto 0);
        mtvec     : std_logic_vector(31 downto 0);
        mip       : std_logic_vector(31 downto 0);
        mie       : std_logic_vector(31 downto 0);

        mcycle       : u64_t;
        minstret     : u64_t;
        mhpmcounters : u64_array_t(3 to 31);
        mhpmevents   : std_logic_matrix_t(3 to 31)(31 downto 0);
        mcounteren   : std_logic_vector(31 downto 0);
        
        mscratch   : std_logic_vector(31 downto 0);
        mepc       : std_logic_vector(31 downto 0);
        mcause     : std_logic_vector(31 downto 0);
        mtval      : std_logic_vector(31 downto 0);
        mconfigptr : std_logic_vector(31 downto 0);

        mtime    : std_logic_vector(63 downto 0);
        mtimecmp : std_logic_vector(63 downto 0);
    end record machine_csr_t;

    procedure handle_accesses(
        signal i_priv  : in std_logic_vector(2 downto 0); 
        signal i_addr  : in std_logic_vector(11 downto 0); 
        signal i_wen   : in std_logic; 
        signal i_wdata : in std_logic_vector(31 downto 0); 
        signal i_mcsr  : inout machine_csr_t; 
        signal o_rdata : out std_logic_vector(31 downto 0); 
        signal o_fault : out std_logic
    );
    
end package CsrDefinitions;

package body CsrDefinitions is
    
    procedure handle_accesses(
        signal i_priv  : in std_logic_vector(2 downto 0); 
        signal i_addr  : in std_logic_vector(11 downto 0); 
        signal i_wen   : in std_logic; 
        signal i_wdata : in std_logic_vector(31 downto 0); 
        signal i_mcsr  : inout machine_csr_t; 
        signal o_rdata : out std_logic_vector(31 downto 0); 
        signal o_fault : out std_logic
    ) is
        variable fault : std_logic;
        variable hpmaddr : natural;
    begin
        case i_priv is
            -- fault occurrs for any unauthorized read
            when "001" =>
                if (i_addr(9 downto 8) /= "00") then
                    fault := '1';
                else
                    fault := '0';
                end if;

            when "010" =>
                if (unsigned(i_addr(9 downto 8)) > 1) then
                    fault := '1';
                else
                    fault := '0';
                end if;

            when "100" =>
                fault := '0';

            when others =>
                fault := '1';
        
        end case;

        if (fault = '0') then
            case to_natural(i_addr) is            
                when 16#300# =>
                    if (i_wen = '1') then
                        i_mcsr.mstatus(31 downto 0) <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mstatus(31 downto 0);
                    end if;

                when 16#301# =>
                    if (i_wen = '1') then
                        i_mcsr.misa <= i_wdata;
                    else
                        o_rdata <= i_mcsr.misa;
                    end if;

                -- when 16#302# =>
                --     if (i_wen = '1') then
                --         i_mcsr.medeleg <= i_wdata;
                --     else
                --         o_rdata <= i_mcsr.medeleg;
                --     end if;

                -- when 16#303# =>
                --     if (i_wen = '1') then
                --         i_mcsr.mideleg <= i_wdata;
                --     else
                --         o_rdata <= i_mcsr.mideleg;
                --     end if;

                when 16#304# =>
                    if (i_wen = '1') then
                        i_mcsr.mie <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mie;
                    end if;

                when 16#305# =>
                    if (i_wen = '1') then
                        i_mcsr.mtvec <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mtvec;
                    end if;

                -- when 16#30A# =>
                --     if (i_wen = '1') then
                --         i_mcsr.menvcfg(31 downto 0) <= i_wdata;
                --     else
                --         o_rdata <= i_mcsr.menvcfg(31 downto 0);
                --     end if;

                when 16#310# =>
                    if (i_wen = '1') then
                        i_mcsr.mstatus(63 downto 32) <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mstatus(63 downto 32);
                    end if;

                -- when 16#31A# =>
                --     if (i_wen = '1') then
                --         i_mcsr.menvcfg(63 downto 32) <= i_wdata;
                --     else
                --         o_rdata <= i_mcsr.menvcfg(63 downto 32);
                --     end if;

                when 16#323# to 16#33F# =>
                    hpmaddr := to_natural(i_addr) - 16#B00#;
                    if (i_wen = '1') then
                        i_mcsr.mhpmcounters(hpmaddr)(31 downto 0) <= unsigned(i_wdata);
                    else
                        o_rdata <= std_logic_vector(i_mcsr.mhpmcounters(hpmaddr)(31 downto 0));
                    end if;

                when 16#340# =>
                    if (i_wen = '1') then
                        i_mcsr.mscratch <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mscratch;
                    end if;

                when 16#341# =>
                    if (i_wen = '1') then
                        i_mcsr.mepc <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mepc;
                    end if;

                when 16#342# =>
                    if (i_wen = '1') then
                        i_mcsr.mcause <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mcause;
                    end if;

                when 16#343# =>
                    if (i_wen = '1') then
                        i_mcsr.mtval <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mtval;
                    end if;

                when 16#344# =>
                    if (i_wen = '1') then
                        i_mcsr.mip <= i_wdata;
                    else
                        o_rdata <= i_mcsr.mip;
                    end if;

                -- when 16#747# =>
                --     if (i_wen = '1') then
                --         i_mcsr.mseccfg(31 downto 0) <= i_wdata;
                --     else
                --         o_rdata <= i_mcsr.mseccfg(31 downto 0);
                --     end if;

                -- when 16#757# =>
                --     if (i_wen = '1') then
                --         i_mcsr.mseccfg(63 downto 32) <= i_wdata;
                --     else
                --         o_rdata <= i_mcsr.mseccfg(63 downto 32);
                --     end if;

                when 16#B00# =>
                    if (i_wen = '1') then
                        i_mcsr.mcycle(31 downto 0) <= unsigned(i_wdata);
                    else
                        o_rdata <= std_logic_vector(i_mcsr.mcycle(31 downto 0));
                    end if;

                when 16#B02# =>
                    if (i_wen = '1') then
                        i_mcsr.minstret(31 downto 0) <= unsigned(i_wdata);
                    else
                        o_rdata <= std_logic_vector(i_mcsr.minstret(31 downto 0));
                    end if;

                when 16#B03# to 16#B1F# =>
                    hpmaddr := to_natural(i_addr) - 16#B00#;
                    if (i_wen = '1') then
                        i_mcsr.mhpmcounters(hpmaddr)(31 downto 0) <= unsigned(i_wdata);
                    else
                        o_rdata <= std_logic_vector(i_mcsr.mhpmcounters(hpmaddr)(31 downto 0));
                    end if;

                when 16#B80# =>
                    if (i_wen = '1') then
                        i_mcsr.mcycle(63 downto 32) <= unsigned(i_wdata);
                    else
                        o_rdata <= std_logic_vector(i_mcsr.mcycle(63 downto 32));
                    end if;

                when 16#B82# =>
                    if (i_wen = '1') then
                        i_mcsr.minstret(63 downto 32) <= unsigned(i_wdata);
                    else
                        o_rdata <= std_logic_vector(i_mcsr.minstret(63 downto 32));
                    end if;

                when 16#B83# to 16#B9F# =>
                    hpmaddr := to_natural(i_addr) - 16#B80#;
                    if (i_wen = '1') then
                        i_mcsr.mhpmcounters(hpmaddr)(63 downto 32) <= unsigned(i_wdata);
                    else
                        o_rdata <= std_logic_vector(i_mcsr.mhpmcounters(hpmaddr)(63 downto 32));
                    end if;

                when 16#C01# =>
                    if (i_wen = '1') then
                        fault := '1';
                    else
                        if i_mcsr.mcounteren(1) = '1' then
                            o_rdata <= std_logic_vector(i_mcsr.mtime(31 downto 0));
                        else
                            -- illegal instruction exception
                        end if;
                    end if;

                when 16#C02# =>
                    if (i_wen = '1') then
                        fault := '1';
                    else
                        if i_mcsr.mcounteren(2) = '1' then
                            o_rdata <= std_logic_vector(i_mcsr.minstret(31 downto 0));
                        else
                            -- illegal instruction exception
                        end if;
                    end if;
                
                when 16#C03# to 16#C1F# =>
                    if (i_wen = '1') then
                        fault := '1';
                    else
                        hpmaddr := to_natural(i_addr) - 16#C00#;
                        if i_mcsr.mcounteren(hpmaddr) = '1' then
                            o_rdata <= std_logic_vector(i_mcsr.mhpmcounters(hpmaddr)(31 downto 0));
                        else
                            -- illegal instruction exception
                        end if;
                    end if;

                    when 16#C80# =>
                    if (i_wen = '1') then
                        fault := '1';
                    else
                        if i_mcsr.mcounteren(0) = '1' then
                            o_rdata <= std_logic_vector(i_mcsr.mcycle(63 downto 32));
                        else
                            -- illegal instruction exception
                        end if;
                    end if;
            
                when 16#C81# =>
                    if (i_wen = '1') then
                        fault := '1';
                    else
                        if i_mcsr.mcounteren(1) = '1' then
                            o_rdata <= std_logic_vector(i_mcsr.mtime(63 downto 32));
                        else
                            -- illegal instruction exception
                        end if;
                    end if;

                when 16#C82# =>
                    if (i_wen = '1') then
                        fault := '1';
                    else
                        if i_mcsr.mcounteren(2) = '1' then
                            o_rdata <= std_logic_vector(i_mcsr.minstret(63 downto 32));
                        else
                            -- illegal instruction exception
                        end if;
                    end if;
                
                when 16#C83# to 16#C9F# =>
                    if (i_wen = '1') then
                        fault := '1';
                    else
                        hpmaddr := to_natural(i_addr) - 16#C80#;
                        if i_mcsr.mcounteren(hpmaddr) = '1' then
                            o_rdata <= std_logic_vector(i_mcsr.mhpmcounters(hpmaddr)(63 downto 32));
                        else
                            -- illegal instruction exception
                        end if;
                    end if;

                when others =>
                    
            
            end case;
            o_fault <= fault;
        end if;
    end procedure;
    
end package body CsrDefinitions;