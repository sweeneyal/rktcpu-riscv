library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.Control.all;
    use scrv.CsrDefinitions.all;

entity ZiCsr is
    port (
        i_clk     : in std_logic;
        i_resetn  : in std_logic;
        i_opcode  : in std_logic_vector(6 downto 0);
        i_funct3  : in std_logic;
        i_csraddr : in std_logic_vector(11 downto 0);
        i_rd      : in std_logic_vector(4 downto 0);
        i_rs1     : in std_logic_vector(4 downto 0);
        i_opA     : in std_logic_vector(31 downto 0);
        o_csrr    : out std_logic_vector(31 downto 0);
        o_csren   : out std_logic;
        o_csrdone : out std_logic;
        i_instret : in std_logic
    );
end entity ZiCsr;

architecture rtl of ZiCsr is
    signal mcsr : machine_csr_t;

    type state_t is (ZICSR_RESET, ZICSR_WAIT_FOR_INSTR, ZICSR_WRITE, ZICSR_SET, ZICSR_CLEAR, ZICSR_DONE);
    type substate_t is (READ_CSR, SET_CSR, WRITE_CSR, CLEAR_CSR, IDLE);
    type zicsr_engine_t is record
        state    : state_t;
        substate : substate_t;
        en       : std_logic;
        wen      : std_logic;
        wdata    : std_logic_vector(31 downto 0);
        csrr     : std_logic_vector(31 downto 0);
        fault    : std_logic;
    end record zicsr_engine_t;
    signal zicsr_engine : zicsr_engine_t;
begin

    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                zicsr_engine.state <= ZICSR_RESET;
            else
                case zicsr_engine.state is
                    -- Start in ZICSR_RESET to ensure same boot up process
                    when ZICSR_RESET =>
                        zicsr_engine.state <= ZICSR_WAIT_FOR_INSTR;
                    
                    -- Wait for an appropriate instruction to start the atomic read-write process
                    when ZICSR_WAIT_FOR_INSTR =>
                        if (i_opcode = cEcallOpcode) then
                            -- Assume a read for all Ecall opcodes
                            zicsr_engine.en <= '1';
                            zicsr_engine.substate <= READ_CSR;
                            case i_funct3(1 downto 0) is
                                when "01" =>
                                    zicsr_engine.state <= ZICSR_WRITE;
                                when "10" =>
                                    zicsr_engine.state <= ZICSR_SET;
                                when "11" =>
                                    zicsr_engine.state <= ZICSR_CLEAR;
                                when others =>
                                    -- Don't read unless it's actually a CSRRx instruction.
                                    zicsr_engine.en <= '0';
                            end case;
                        else
                            zicsr_engine.en <= '0';
                        end if;

                    -- When we're in the read write process, determine which substate to go to.
                    when ZICSR_WRITE | ZICSR_SET | ZICSR_CLEAR =>
                        o_csrren         <= '0';
                        zicsr_engine.wen <= '0';
                        case substate is
                            -- Always read the CSR, but only plan to write it if the destination reg is nonzero.
                            when READ_CSR =>
                                if (i_rd /= "00000") then
                                    o_csrren <= '1';
                                end if;

                                if (zicsr_engine.state = ZICSR_WRITE) then
                                    zicsr_engine.substate <= WRITE_CSR;
                                elsif (zicsr_engine.state = ZICSR_SET) then
                                    zicsr_engine.substate <= SET_CSR;
                                else
                                    zicsr_engine.substate <= CLEAR_CSR;
                                end if;
                            
                            -- We always write in this state
                            when WRITE_CSR =>
                                zicsr_engine.wen <= '1';
                                if (i_funct3(2) = '1') then
                                    zicsr_engine.wdata <= std_logic_vector(resize(unsigned(i_rs1), 32));
                                else
                                    zicsr_engine.wdata <= i_opA;
                                end if;
                                zicsr_engine.substate <= IDLE;
                                zicsr_engine.state    <= ZICSR_DONE;

                            -- We need to perform a bitwise or with either an unsigned immediate or
                            -- with operand A.
                            when SET_CSR =>
                                if (i_funct3(2) = '1') then
                                    if (i_rs1 = "00000") then
                                        zicsr_engine.wen <= '0';
                                    end if;
                                    zicsr_engine.wdata <= 
                                        std_logic_vector(resize(unsigned(i_rs1), 32)) or zicsr_engine.csrr;
                                else
                                    zicsr_engine.wdata <= i_opA or zicsr_engine.csrr;
                                    zicsr_engine.wen   <= '1';
                                end if;
                                zicsr_engine.substate <= IDLE;
                                zicsr_engine.state    <= ZICSR_DONE;

                            -- We need to perform a bitwise and with the inverse of either operand A or
                            -- an immediate.
                            when CLEAR_CSR =>
                                if (i_funct3(2) = '1') then
                                    if (i_rs1 = "00000") then
                                        zicsr_engine.wen <= '0';
                                    end if;
                                    zicsr_engine.wdata <= 
                                        (not std_logic_vector(resize(unsigned(i_rs1), 32))) and zicsr_engine.csrr;
                                else
                                    zicsr_engine.wdata <= (not i_opA) and zicsr_engine.csrr;
                                    zicsr_engine.wen   <= '1';
                                end if;
                                zicsr_engine.substate <= IDLE;
                                zicsr_engine.state    <= ZICSR_DONE;

                            -- Once we complete the read-write process, skip a cycle and then go back to wait for the next INSTR.
                            when others =>
                                zicsr_engine.substate <= IDLE;
                                zicsr_engine.state    <= ZICSR_DONE;
                        end case;

                    when others =>
                    zicsr_engine.state <= ZICSR_WAIT_FOR_INSTR;
                
                end case;                
            end if;
        end if;
    end process StateMachine;

    o_csrr <= zicsr_engine.csrr;

    CsrAccess: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
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

                mcsr.mcycle   <= (others => '0');
                mcsr.minstret <= (others => '0');
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
            else
                mcsr.mcycle <= std_logic_vector(unsigned(mcsr.mcycle) + 1);

                if (en = '1') then
                    handle_accesses(
                        i_priv  => "100",
                        i_addr  => i_csraddr,
                        i_wen   => zicsr_engine.wen,
                        i_wdata => zicsr_engine.wdata,
                        i_mcsr  => mcsr,
                        o_rdata => zicsr_engine.csrr,
                        o_fault => zicsr_engine.fault
                    );
                else
                    if (i_instret = '1') then
                        mcsr.minstret <= std_logic_vector(unsigned(mcsr.minstret) + 1);
                    end if;
                end if;
            end if;
        end if;
    end process CsrAccess;
    
    
end architecture rtl;