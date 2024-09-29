library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

package CsrDefinitions is

    ------------------------------------------
    -- MIP and MIE Interrupt Enable Fields
    ------------------------------------------
    -- supervisor software interrupts
    constant cSSI : natural := 1;
    -- machine software interrupts
    constant cMSI : natural := 3;
    -- supervisor timer interrupts
    constant cSTI : natural := 5;
    -- machine timer interrupts
    constant cMTI : natural := 7;
    -- supervisor external interrupts
    constant cSEI : natural := 9;
    -- machine external interrupts
    constant cMEI : natural := 11;
    
    
    ---------------------------------
    -- MSTATUS FIELDS (RV32I)
    ---------------------------------
    -- global supervisor interrupt enable
    constant cSIE  : natural := 1;

    -- global machine interrupt enable
    constant cMIE  : natural := 3;

    -- holds interrupt enable bit prior to trap
    constant cSPIE : natural := 5;

    -- (User Byte Endianess), leave 0 as little endian
    constant cUBE  : natural := 6;

    -- holds interrupt enable bit prior to trap
    constant cMPIE : natural := 7;

    -- contains the previous privilege mode
    constant cSPP  : natural := 8;

    -- vector extension state
    -- leave 0 as not supported
    constant cVS_0 : natural := 9;
    constant cVS_1 : natural := 10;
    
    -- contains the previous privilege mode
    constant cMPP_0 : natural := 11;
    constant cMPP_1 : natural := 12;

    -- Floating state bits
    -- leave 0 as not supported
    constant cFS_0 : natural := 13;
    constant cFS_1 : natural := 14;

    -- additional user mode extensions state
    -- leave 0 as not supported
    constant cXS_0 : natural := 15;
    constant cXS_1 : natural := 16;

    -- this bit modifies the effective privilege mode (Modify PRiVilege)
    -- when 0, loads and stores behave as normal. Leave set to 0 if
    -- U mode is not supported.
    constant cMPRV : natural := 17;

    -- this bit modifies the privilege with which S mode loads and stores access
    -- virtual memory. When 0, S mode accesses to pages accessible by U 
    -- mode will fault. Leave 0 if S mode is not supported.
    -- (Supervisor User Memory access)
    constant cSUM  : natural := 18;

    -- this bit modifies the privilege with which loads access virtual memory
    -- when 0, only loads from pages marked readable will succeed.
    -- Leave 0 if S mode is not supported.
    -- (Make eXecutable Readable)
    constant cMXR  : natural := 19;

    -- this bit supports intercepting supervisor virtual memory management operations.
    -- Leave 0 if S-Mode not supported.
    -- (Trap Virtual Memory)
    constant cTVM  : natural := 20;
    -- this bit supports intercepting the WFI instruction. When 0, the WFI instruction
    -- can be executed in lower privileges. When 1, then if WFI is executed in any
    -- less-privileged mode and does not complete ithin a time limit, throw an illegal
    -- instruction exception. TW is 0 if no modes less privileged than M exist.
    -- (Timeout Wait)
    constant cTW   : natural := 21;
    -- this bit supports intercepting the supervisor exception return instruction, SRET.
    -- when 1, attempts to execute SRET while executing in S mode will raise an illegal
    -- instruction exception. Leave 0 if S-Mode is not supported.
    -- (Trap SRet)
    constant cTSR  : natural := 22;

    -- dirty state bit for FS, XS, and VS.
    -- leave 0
    constant cSD   : natural := 31;

    ---------------------------------
    -- MSTATUSH FIELDS (RV32I)
    ---------------------------------

    -- (Supervisor Byte Endianess), leave 0 as little endian
    constant cSBE : natural := 4;
    -- (Machine Byte Endianess), leave 0 as little endian
    constant cMBE : natural := 5;

    ---------------------------------
    -- MACHINE CSR RECORD
    ---------------------------------

    type machine_csr_t is record
        -- register the reports the ISA supported by the hart 
        misa      : std_logic_vector(31 downto 0);
        -- register that contains the JEDEC code of the core provider
        mvendorid : std_logic_vector(31 downto 0);
        -- Read-only register encoding the base microarchitecture of the hart
        marchid   : std_logic_vector(31 downto 0);
        -- Unique encoding of the version of the processor implementation
        mimpid    : std_logic_vector(31 downto 0);
        -- Read-only register containing the integer ID of the hardware thread running the code
        mhartid   : std_logic_vector(31 downto 0);
        -- Register that keeps track of and controls the hart's current operating state
        mstatus   : std_logic_vector(63 downto 0);
        -- Register that holds trap vector configuration
        mtvec     : std_logic_vector(31 downto 0);
        -- Register that indicates what interrupts are pending
        mip       : std_logic_vector(31 downto 0);
        -- Register that indicates what interrupts are enabled
        mie       : std_logic_vector(31 downto 0);

        -- register that counts the number of clock cycles elapsed 
        mcycle       : u64_t;
        -- register that counts the number of instructions retired
        minstret     : u64_t;
        -- registers that count the number of events in the corresponding hpm events
        mhpmcounters : u64_array_t(3 to 31);
        -- registers that holds what event increments the hpm counters
        mhpmevents   : std_logic_matrix_t(3 to 31)(31 downto 0);
        -- register that controls which of the counters can be read
        mcounteren   : std_logic_vector(31 downto 0);
        -- register that controls which of the counters increment
        mcountinhibit   : std_logic_vector(31 downto 0);
        
        -- register dedicated for use by machine mode, usually used to hold a pointer
        mscratch   : std_logic_vector(31 downto 0);
        -- register that is written with the exception address
        mepc       : std_logic_vector(31 downto 0);
        -- register that is written with a code indicating the event that caused the trap
        mcause     : std_logic_vector(31 downto 0);
        --
        mtval      : std_logic_vector(31 downto 0);
        --
        mconfigptr : std_logic_vector(31 downto 0);

        -- real-time counter that increments at a constant frequency
        mtime    : std_logic_vector(63 downto 0);
        -- time compare register that creates a pending interrupt whenever mtime
        -- is greater than or equal to mtimecmp
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
                    hpmaddr := to_natural(i_addr) - 16#323#;
                    if (i_wen = '1') then
                        i_mcsr.mhpmevents(hpmaddr)(31 downto 0) <= i_wdata;
                    else
                        o_rdata <= std_logic_vector(i_mcsr.mhpmevents(hpmaddr)(31 downto 0));
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