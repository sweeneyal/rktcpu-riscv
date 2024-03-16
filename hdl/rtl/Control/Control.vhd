library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;
    use universal.CommonTypesPkg.all;

library scrv;
    use scrv.RiscVDefinitions.all;

entity Control is
    port (
        i_clk    : in std_logic;

        -- Fetch signals
        i_instr  : in std_logic_vector(31 downto 0);
        i_valid  : in std_logic;

        -- Control signals
        o_pc     : out std_logic_vector(31 downto 0);
        o_opcode : out std_logic_vector(6 downto 0);
        o_rs1    : out std_logic_vector(4 downto 0);
        o_rs2    : out std_logic_vector(4 downto 0);
        o_rd     : out std_logic_vector(4 downto 0);
        o_funct3 : out std_logic_vector(2 downto 0);
        o_funct7 : out std_logic_vector(6 downto 0);
        o_itype  : out std_logic_vector(11 downto 0);
        o_stype  : out std_logic_vector(11 downto 0);
        o_btype  : out std_logic_vector(12 downto 0);
        o_utype  : out std_logic_vector(19 downto 0);
        o_jtype  : out std_logic_vector(20 downto 0);

        i_jtaken : in std_logic;
        i_btaken : in std_logic;
        i_nxtpc  : in std_logic_vector(31 downto 0);

        -- Control I/O
        o_csrren : out std_logic;
        o_csrr   : out std_logic_vector(31 downto 0);
        i_csrwen : in std_logic;
        i_csrw   : in std_logic_vector(31 downto 0);

        -- Debug Signals
    );
end entity Control;

architecture rtl of Control is
    signal mcsr : machine_csr_t;

    type fetch_state_t is (FETCH_RESET, FETCH_REQUEST, FETCH_PENDING);
    type fetch_engine_t is record
        state   : fetch_state_t;
        pc      : unsigned(31 downto 0);
        restart : std_logic;
    end record fetch_engine_t;
    signal fetch_engine : fetch_engine_t;

    type execute_state_t is (EX_WAIT, EX_EXECUTE, EX_ALU_WAIT, EX_BRANCH, 
        EX_JUMP, EX_FENCE, EX_MEM_ACCESS, EX_SYSTEM);
    type execute_engine_t is record
        state : execute_state_t;
        pc    : unsigned(31 downto 0);
        instr : std_logic_vector(31 downto 0);
    end record execute_engine_t;
    signal execute_engine : execute_engine_t;
    
begin

    FetchStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            case fetch_engine.state is
                when FETCH_RESET =>
                    fetch_engine.state <= FETCH_REQUEST;
            
                when FETCH_REQUEST =>
                    fetch_engine.state <= FETCH_PENDING;

                when FETCH_PENDING =>
                    if (i_btaken or i_jtaken = '1') then
                        fetch_engine.state <= FETCH_RESET;
                        fetch_engine.pc    <= i_nxtpc;
                    elsif (i_ivalid = '1') then
                        fetch_engine.state <= FETCH_REQUEST;
                        fetch_engine.pc    <= fetch_engine.pc + 1;
                    end if;

                when others =>
                    fetch_engine.state <= FETCH_RESET;
            
            end case;
        end if;
    end process FetchStateMachine;

    -- Handle case where FIFO is full

    ExecuteStateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            case execute_engine.state is
                when EX_WAIT =>
                    if (ivalid = '1') then
                        execute_engine.instr <= instr;
                        execute_engine.state <= EX_EXECUTE;
                    end if;
            
                when EX_EXECUTE =>
                    if (not verify_instruction(execute_engine.instr)) then
                        execute_engine.state <= EX_SYSTEM;
                    else
                        case get_opcode(execute_engine.instr) is
                            when cAluOpcode | cAluImmedOpcode =>
                                execute_engine.state <= EX_ALU_WAIT;
                            
                            when cJumpOpcode | cJumpRegOpcode =>
                                execute_engine.state <= EX_JUMP;

                            when cBranchOpcode =>
                                execute_engine.state <= EX_BRANCH;

                            when cFenceOpcode =>
                                execute_engine.state <= EX_FENCE;
                            
                            when cEcallOpcode =>
                                execute_engine.state <= EX_SYSTEM;

                            when cLoadOpcode | cLoadUpperOpcode | cStoreOpcode =>
                                execute_engine.state <= EX_MEM_ACCESS;
                        
                            when others =>
                                null;
                        end case;
                    end if;

                when EX_ALU_WAIT =>
                    -- When we're here, we're waiting for the ALU to complete the operation.
                    -- Some operations (specifically multiplication, division, and any floating point ops)
                    -- take more cycles.

                    -- We're trying to make the common case fast.
                    if (i_aluvalid = '1') then
                        execute_engine.state <= EX_WAIT;
                        execute_engine.pc    <= execute_engine.pc + 1;
                    end if;

                when EX_JUMP =>
                    if (i_jtaken = '1') then
                        execute_engine.state <= EX_WAIT;
                        execute_engine.pc    <= i_nxtpc;
                    end if;

                when EX_BRANCH =>
                    if (i_btaken = '1') then
                        execute_engine.state <= EX_WAIT;
                        execute_engine.pc    <= i_nxtpc;
                    end if;

                when EX_FENCE =>
                    execute_engine.state <= EX_WAIT;
                    execute_engine.pc    <= execute_engine.pc + 1;

                when EX_MEM_ACCESS =>
                    if (i_memdone = '1') then
                        execute_engine.state <= EX_WAIT;
                        execute_engine.pc    <= execute_engine.pc + 1;
                    end if;

                when EX_SYSTEM =>
                    if (sysdone = '1') then
                        execute_engine.state <= EX_WAIT;
                        if (get_funct3(execute_engine.instr) = cEnvFunct3) then
                            case get_funct12(execute_engine.instr) is
                                when cEcallFunct12 =>
                                    -- set flag that ecall occurred
                                when cEbreakFunct12 =>
                                    -- set flag that ebreak occurred
                                when cMretFunct12 | cSretFunct12 =>
                                    execute_engine.state <= EX_TRAP_EXIT;
                                when others =>
                                    
                            end case;
                        else
                            -- instruction error
                        end if;
                    end if;

                when others =>
                    execute_engine.state <= EX_WAIT;
            
            end case;
        end if;
    end process ExecuteStateMachine;

    o_opcode <= get_opcode(execute_engine.instr);
    o_funct3 <= get_funct3(execute_engine.instr);
    o_funct7 <= get_funct7(execute_engine.instr);
    
    CsrControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '1') then
                -- Machine CSRs
                mcsr.misa      <= (others => '0');
                mcsr.mvendorid <= (others => '0');
                mcsr.marchid   <= (others => '0');
                mcsr.mimpid    <= (others => '0');
                mcsr.mhartid   <= (others => '0');
                mcsr.mstatus   <= (others => '0');
                mcsr.mstatush  <= (others => '0');
                mcsr.mtvec     <= (others => '0');
                mcsr.medeleg   <= (others => '0');
                mcsr.mideleg   <= (others => '0');
                mcsr.mip       <= (others => '0');
                mcsr.mie       <= (others => '0');

                mcsr.mcycle        <= (others => '0');
                mcsr.minstret      <= (others => '0');
                for ii in 3 to 31 loop
                    mcsr.mhpmcounters(ii) <= (others => '0');
                end loop;
                mcsr.mhpmevents    <= (others => '0');
                mcsr.mcounteren    <= (others => '0');
                mcsr.mcountinhibit <= (others => '0');
                
                mcsr.mscratch   <= (others => '0');
                mcsr.mepc       <= (others => '0');
                mcsr.mcause     <= (others => '0');
                mcsr.mtval      <= (others => '0');
                mcsr.mconfigptr <= (others => '0');
                mcsr.menvcfg    <= (others => '0');
                mcsr.mseccfg    <= (others => '0');

                mcsr.mtime    <= (others => '0');
                mcsr.mtimecmp <= (others => '0');

            elsif (i_ren = '1' or i_wen = '1') then
                handle_accesses(
                    i_priv  => priv,
                    i_addr  => csraddr,
                    i_wen   => wen,
                    i_ren   => ren,
                    i_wdata => wdata,
                    i_mcsr  => mcsr,
                    o_rdata => rdata,
                    o_fault => fault
                );

            else
                if (i_inc = '1') then
                    mcsr.mcycle   <= std_logic_vector(unsigned(mcsr.mcycle) + 1);
                    mcsr.minstret <= std_logic_vector(unsigned(mcsr.minstret) + 1);
                    -- for ii in 3 to 31 loop
                    --     mcsr.mhpmcounters(ii) <= std_logic_vector(unsigned(mcsr.mhpmcounters(ii)) + 1);
                    -- end loop;
                end if;

            end if;
        end if;
    end process CsrControl;
    
end architecture rtl;