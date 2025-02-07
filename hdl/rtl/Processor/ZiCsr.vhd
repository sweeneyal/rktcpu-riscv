library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;
    use rktcpu.RiscVDefinitions.all;
    use rktcpu.CsrDefinitions.all;

entity ZiCsr is
    generic (
        cTrapBaseAddress : std_logic_vector(31 downto 0) := x"00100000"
    );
    port (
        i_clk : in std_logic;
        i_resetn : in std_logic;

        i_ctrl_zcsr : in zicsr_controls_t;
        i_opA       : in std_logic_vector(31 downto 0);
        o_csrr      : out std_logic_vector(31 downto 0);
        o_csrren    : out std_logic;
        o_csrdone   : out std_logic;
        i_instret   : in std_logic;

        i_swirpt  : in std_logic;
        i_extirpt : in std_logic;
        i_tmrirpt : in std_logic;
        i_irpts   : in std_logic_vector(15 downto 0);

        o_irptvalid : out std_logic;
        o_irptpc    : out std_logic_vector(31 downto 0);

        o_mepc      : out std_logic_vector(31 downto 0);
        o_mepcvalid : out std_logic
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

    -- TODO: Remove for actual priv implementation
    signal priv : std_logic_vector(2 downto 0) := "100";

    signal rs1 : std_logic_vector(4 downto 0) := "00000";
    signal rd  : std_logic_vector(4 downto 0) := "00000";
    signal opA : std_logic_vector(31 downto 0) := x"00000000";
    signal funct3 : std_logic_vector(2 downto 0) := "000";
    signal csraddr : std_logic_vector(11 downto 0) := x"000";

    signal mip   : std_logic_vector(31 downto 0) := x"00000000";
    signal mip_c : std_logic_vector(31 downto 0) := x"00000000";
    signal mcause : std_logic_vector(30 downto 0) := (others => '0');

    signal irptvalid : std_logic := '0';

    function get_highest_priority_irpt(pending : std_logic_vector) return std_logic_vector is
    begin
        for ii in 0 to pending'length - 1 loop
            if (pending(ii) = '1') then
                return to_slv(ii, 31);
            end if;
        end loop;
        return to_slv(0, 31);
    end function;
begin
    
    o_csrdone <= bool2bit(zicsr_engine.state = ZICSR_DONE);
    o_csrr    <= zicsr_engine.csrr;

    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                zicsr_engine.state <= ZICSR_RESET;
                zicsr_engine.en    <= '0';
                zicsr_engine.wen   <= '0';
                zicsr_engine.wdata <= x"00000000";
                zicsr_engine.fault <= '0';

                o_csrren <= '0';
            else
                case zicsr_engine.state is
                    -- Start in ZICSR_RESET to ensure same boot up process
                    when ZICSR_RESET =>
                        zicsr_engine.state <= ZICSR_WAIT_FOR_INSTR;
                    
                    -- Wait for an appropriate instruction to start the atomic read-write process
                    when ZICSR_WAIT_FOR_INSTR =>
                        o_csrren <= '0';
                        if (i_ctrl_zcsr.en = '1') then
                            rs1     <= i_ctrl_zcsr.rs1;
                            rd      <= i_ctrl_zcsr.rd;
                            opA     <= i_opA;
                            funct3  <= i_ctrl_zcsr.funct3;
                            csraddr <= i_ctrl_zcsr.itype;

                            -- Assume a read for all Ecall opcodes
                            zicsr_engine.en <= '1';
                            zicsr_engine.substate <= READ_CSR;
                            case i_ctrl_zcsr.funct3(1 downto 0) is
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
                        case zicsr_engine.substate is
                            -- Always read the CSR, but only plan to write it if the destination reg is nonzero.
                            when READ_CSR =>
                                if (rd /= "00000") then
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
                                if (funct3(2) = '1') then
                                    zicsr_engine.wdata <= std_logic_vector(resize(unsigned(rs1), 32));
                                else
                                    zicsr_engine.wdata <= opA;
                                end if;
                                zicsr_engine.substate <= IDLE;
                                zicsr_engine.state    <= ZICSR_DONE;

                            -- We need to perform a bitwise or with either an unsigned immediate or
                            -- with operand A.
                            when SET_CSR =>
                                if (funct3(2) = '1') then
                                    if (rs1 = "00000") then
                                        zicsr_engine.wen <= '0';
                                    end if;
                                    zicsr_engine.wdata <= 
                                        std_logic_vector(resize(unsigned(rs1), 32)) or zicsr_engine.csrr;
                                else
                                    zicsr_engine.wdata <= opA or zicsr_engine.csrr;
                                    zicsr_engine.wen   <= '1';
                                end if;
                                zicsr_engine.substate <= IDLE;
                                zicsr_engine.state    <= ZICSR_DONE;

                            -- We need to perform a bitwise and with the inverse of either operand A or
                            -- an immediate.
                            when CLEAR_CSR =>
                                if (funct3(2) = '1') then
                                    if (rs1 = "00000") then
                                        zicsr_engine.wen <= '0';
                                    end if;
                                    zicsr_engine.wdata <= 
                                        (not std_logic_vector(resize(unsigned(rs1), 32))) and zicsr_engine.csrr;
                                else
                                    zicsr_engine.wdata <= (not opA) and zicsr_engine.csrr;
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
                        zicsr_engine.en    <= '0';
                        zicsr_engine.wen   <= '0';
                
                end case;                
            end if;
        end if;
    end process StateMachine;

    mip(31 downto 16) <= i_irpts;
    mip(cMEI) <= i_extirpt;
    mip(cMTI) <= i_tmrirpt;
    mip(cMSI) <= i_swirpt;

    mip_c <= mcsr.mie and (mcsr.mip or mip);
    irptvalid <= bool2bit((mcsr.mip and mcsr.mie) /= x"00000000" and 
                    mcsr.mstatus(cMIE) = '1');
    mcause <= get_highest_priority_irpt(mip_c);

    o_mepc      <= mcsr.mepc;
    o_mepcvalid <= i_ctrl_zcsr.mret;

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
                mcsr.mtvec     <= cTrapBaseAddress(31 downto 2) & "00";
                -- mcsr.medeleg   <= (others => '0');
                -- mcsr.mideleg   <= (others => '0');
                mcsr.mip       <= (others => '0');
                mcsr.mie       <= (others => '0');

                mcsr.mcycle   <= (others => '0');
                mcsr.minstret <= (others => '0');
                for ii in 3 to 31 loop
                    mcsr.mhpmcounters(ii) <= (others => '0');
                    mcsr.mhpmevents(ii)   <= (others => '0');
                end loop;
                mcsr.mcounteren    <= (others => '0');
                mcsr.mcountinhibit <= (others => '0');
                
                mcsr.mscratch   <= (others => '0');
                mcsr.mepc       <= (others => '0');
                mcsr.mcause     <= (others => '0');
                mcsr.mtval      <= (others => '0');
                mcsr.mconfigptr <= (others => '0');
                -- mcsr.menvcfg    <= (others => '0');
                -- mcsr.mseccfg    <= (others => '0');

                zicsr_engine.csrr  <= x"00000000";
            else
                mcsr.mcycle     <= unsigned(mcsr.mcycle) + to_unsigned(1, 64);
                mcsr.mip        <= mip_c;
                -- set mcause to whatever is currently interrupting
                mcsr.mcause(31) <= bool2bit(mcsr.mip /= x"00000000");
                mcsr.mcause(30 downto 0) <= mcause;

                -- Stall this a few cycles until the irptpc is correct. This is fine, 
                -- since cycles of delay before the interrupt takes hold just means more instructions
                -- will be completed.
                
                o_irptvalid <= irptvalid;
                -- look up address for trap based on 4 * cause + mtvec
                -- force PC to new address
                o_irptpc    <= std_logic_vector(unsigned(mcsr.mtvec) + (unsigned(mcause(29 downto 0)) & "00"));

                -- Add logic here to:
                -- capture the current privilege level into a csr
                if (irptvalid = '1') then
                    -- turn off mie
                    mcsr.mstatus(cMIE)  <= '0';
                    mcsr.mstatus(cMPIE) <= mcsr.mstatus(cMIE);
                    -- store the captured pc into mepc
                    mcsr.mepc           <= i_ctrl_zcsr.pc;
                elsif (i_ctrl_zcsr.mret = '1') then
                    mcsr.mstatus(cMIE)  <= mcsr.mstatus(cMPIE);
                    mcsr.mstatus(cMPIE) <= '1';
                end if;

                -- set mtval to the fault address if it's an instruction fault, 
                -- but since mtval is readonly 0, then I won't handle this.

                if (zicsr_engine.en = '1') then
                    handle_accesses(
                        i_priv  => priv,
                        i_addr  => csraddr,
                        i_wen   => zicsr_engine.wen,
                        i_wdata => zicsr_engine.wdata,
                        i_mcsr  => mcsr,
                        o_rdata => zicsr_engine.csrr,
                        o_fault => zicsr_engine.fault
                    );
                else
                    if (i_instret = '1') then
                        mcsr.minstret <= unsigned(mcsr.minstret) + to_unsigned(1, 64);
                    end if;
                end if;
            end if;
        end if;
    end process CsrAccess;
    
end architecture rtl;