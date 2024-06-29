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

entity RktCpuCore is
    generic (
        cGenerateLoggers : boolean := false
    );
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- Add debug ports

        o_instr_addr   : out std_logic_vector(31 downto 0);
        o_instr_ren    : out std_logic;
        o_instr_wen    : out std_logic_vector(3 downto 0);
        o_instr_wdata  : out std_logic_vector(31 downto 0);
        i_instr_rdata  : in std_logic_vector(31 downto 0);
        i_instr_rvalid : in std_logic;

        o_data_addr   : out std_logic_vector(31 downto 0);
        o_data_ren    : out std_logic;
        o_data_wen    : out std_logic_vector(3 downto 0);
        o_data_wdata  : out std_logic_vector(31 downto 0);
        i_data_rdata  : in std_logic_vector(31 downto 0);
        i_data_rvalid : in std_logic
    );
end entity RktCpuCore;

architecture rtl of RktCpuCore is
    signal ctrl_cmn  : common_controls_t;
    signal ctrl_alu  : alu_controls_t;
    signal ctrl_mem  : mem_controls_t;
    signal ctrl_brnc : branch_controls_t;
    signal ctrl_zcsr : zicsr_controls_t;
    signal ctrl_jal  : jal_controls_t;

    signal nxtpc      : std_logic_vector(31 downto 0) := x"00000000";
    signal pcwen      : std_logic := '0';
    signal reg_opA    : std_logic_vector(31 downto 0) := x"00000000";
    signal reg_opB    : std_logic_vector(31 downto 0) := x"00000000";
    signal opA        : std_logic_vector(31 downto 0) := x"00000000";
    signal opB        : std_logic_vector(31 downto 0) := x"00000000";
    signal lsu_immed  : std_logic_vector(31 downto 0) := x"00000000";
    signal jump_op    : std_logic_vector(31 downto 0) := x"00000000";
    signal jump_immed : std_logic_vector(31 downto 0) := x"00000000";
    
    signal alu_res       : std_logic_vector(31 downto 0) := x"00000000";
    signal lsu_addr      : std_logic_vector(31 downto 0) := x"00000000";
    signal branch_addr   : std_logic_vector(31 downto 0) := x"00000000";
    signal jump_addr     : std_logic_vector(31 downto 0) := x"00000000";
    signal jump_pjpc     : std_logic_vector(31 downto 0) := x"00000000";
    signal memaccess_reg_opA : std_logic_vector(31 downto 0) := x"00000000";
    signal memaccess_reg_opB : std_logic_vector(31 downto 0) := x"00000000";
    signal memaccess_opA : std_logic_vector(31 downto 0) := x"00000000";
    signal memaccess_opB : std_logic_vector(31 downto 0) := x"00000000";
    signal csrr          : std_logic_vector(31 downto 0) := x"00000000";
    signal csrdone       : std_logic := '0';
    signal instret       : std_logic := '0';
    signal branch_wen    : std_logic := '0';

    signal alu_res_ma    : std_logic_vector(31 downto 0) := x"00000000";
    signal jump_pjpc_ma  : std_logic_vector(31 downto 0) := x"00000000";
    signal lsu_rdata     : std_logic_vector(31 downto 0) := x"00000000";
    signal writeback_res : std_logic_vector(31 downto 0) := x"00000000";
begin

    -------------------------------------------------------------------------------------------------
    -- Fetch and Decode Stage
    -------------------------------------------------------------------------------------------------

    eControl : entity rktcpu.ControlEngine
    port map (
        i_clk     => i_clk,
        i_resetn  => i_resetn,
        o_pc      => o_instr_addr,
        o_iren    => o_instr_ren,
        i_instr   => i_instr_rdata,
        i_ivalid  => i_instr_rvalid,
        i_mvalid  => i_data_rvalid,
        i_csrdone => csrdone,

        o_ctrl_cmn  => ctrl_cmn,
        o_ctrl_alu  => ctrl_alu,
        o_ctrl_mem  => ctrl_mem,
        o_ctrl_brnc => ctrl_brnc,
        o_ctrl_zcsr => ctrl_zcsr,
        o_ctrl_jal  => ctrl_jal,

        i_pc    => nxtpc, 
        i_pcwen => pcwen 
    );


    eRegisters : entity rktcpu.BramRegisterFile
    generic map (
        cGenerateLoggers => cGenerateLoggers
    ) port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,

        i_rs1    => ctrl_cmn.rs1,
        o_opA    => reg_opA,
        i_rs2    => ctrl_cmn.rs2,
        o_opB    => reg_opB,

        i_rd     => ctrl_cmn.rd,
        i_rdwen  => ctrl_cmn.rdwen,
        i_res    => writeback_res
    );

    --------------------------------------------------------------------------------------------------------------
    -- Execute Stage
    --------------------------------------------------------------------------------------------------------------

    OperandMuxes: process(ctrl_cmn, alu_res, writeback_res, reg_opA, reg_opB, ctrl_jal)
    begin
        -- Handle hazards
        if (ctrl_cmn.hzd_rs1_ex(cMemAccessIdx) = '1') then
            opA <= alu_res;
        elsif (ctrl_cmn.hzd_rs1_ex(cWritebackIdx) = '1') then
            opA <= writeback_res;

        -- Use the adder in the ALU to complete LUI and AUIPC instructions.
        elsif (ctrl_cmn.upper = '1') then
            opA <= x"00000000";
        elsif (ctrl_cmn.auipc = '1') then
            opA <= ctrl_cmn.pc;

        -- Handle all other cases (registers)
        else
            opA <= reg_opA;
        end if;

        -- Handle hazards
        if (ctrl_cmn.hzd_rs2_ex(cMemAccessIdx) = '1') then
            opB <= alu_res;
        elsif (ctrl_cmn.hzd_rs2_ex(cWritebackIdx) = '1') then
            opB <= writeback_res;

        -- Use the adder in the ALU to complete LUI and AUIPC instructions.
        elsif (ctrl_cmn.upper = '1' or ctrl_cmn.auipc = '1') then
            opB <= std_logic_vector(resize(signed(ctrl_cmn.utype), 32));

        -- Handle the immediates and normal registers here.
        else
            if (ctrl_cmn.iimmed = '1') then
                opB <= std_logic_vector(resize(signed(ctrl_cmn.itype), 32));
            else
                opB <= reg_opB;
            end if;
        end if;

        -- Handle LSU immediates.
        if (ctrl_cmn.store = '1') then
            lsu_immed <= std_logic_vector(resize(signed(ctrl_cmn.stype), 32));
        else
            -- Leverage this to complete JALR instructions as well as load instructions.
            lsu_immed <= std_logic_vector(resize(signed(ctrl_cmn.itype), 32));
        end if;

        -- Jump functions
        if (ctrl_jal.jalr = '1') then
            jump_op    <= opA;
            jump_immed <= std_logic_vector(resize(signed(ctrl_cmn.itype), 32));
        else
            jump_op    <= ctrl_cmn.pc;
            jump_immed <= std_logic_vector(resize(signed(ctrl_cmn.jtype), 32));
        end if;
    end process OperandMuxes;

    eAlu : entity rktcpu.AluCore
    port map (
        i_clk      => i_clk,
        i_resetn   => i_resetn,
        i_ctrl_alu => ctrl_alu,
        i_stall    => ctrl_cmn.stall,
        i_opA      => opA,
        i_opB      => opB,
        o_res      => alu_res
    );

    MiscPipelineRegs: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                lsu_addr          <= x"00000000";
                branch_addr       <= x"00000000";
                jump_addr         <= x"00000000";
                jump_pjpc         <= x"00000000";
                memaccess_reg_opA <= x"00000000";
                memaccess_reg_opB <= x"00000000";
            else
                lsu_addr      <= std_logic_vector(signed(opA) + signed(lsu_immed));
                branch_addr   <= std_logic_vector(signed(ctrl_cmn.pc) + signed(ctrl_cmn.btype));
                jump_addr     <= std_logic_vector(signed(jump_op) + signed(jump_immed));
                jump_pjpc     <= std_logic_vector(signed(ctrl_cmn.pc) + to_signed(4, 32));
                memaccess_reg_opA <= opA;
                memaccess_reg_opB <= opB;
            end if;
        end if;
    end process MiscPipelineRegs;

    --------------------------------------------------------------------------------------------------------------
    -- Memaccess Stage
    --------------------------------------------------------------------------------------------------------------

    MemAccessHazards: process(ctrl_cmn, memaccess_reg_opA, memaccess_reg_opB, writeback_res)
    begin
        if (ctrl_cmn.hzd_rs1_ma) then
            memaccess_opA <= writeback_res;
        else
            memaccess_opA <= memaccess_reg_opA;
        end if;

        if (ctrl_cmn.hzd_rs2_ma) then
            memaccess_opB <= writeback_res;
        else
            memaccess_opB <= memaccess_reg_opB;
        end if;
    end process MemAccessHazards;

    BranchLogic: process(ctrl_brnc, memaccess_opA, memaccess_opB)
    begin
        if (ctrl_brnc.en = '1') then
            if (ctrl_brnc.blt = '1') then
                if (ctrl_brnc.uns = '1') then
                    branch_wen <= ctrl_brnc.inv 
                        xor bool2bit(unsigned(memaccess_opA) < unsigned(memaccess_opB));
                else
                    branch_wen <= ctrl_brnc.inv 
                        xor bool2bit(signed(memaccess_opA) < signed(memaccess_opB));
                end if;
            else
                branch_wen <= ctrl_brnc.inv 
                    xor bool2bit(memaccess_opA = memaccess_opB);
            end if;
        else
            branch_wen <= '0';
        end if;
    end process BranchLogic;

    NxtPcMux: process(branch_wen, jump_addr, branch_addr)
    begin
        if (branch_wen = '1') then
            nxtpc <= branch_addr;
        else
            nxtpc <= jump_addr;
        end if;
    end process NxtPcMux;

    pcwen <= branch_wen or ctrl_jal.en;

    Aligner: process(memaccess_opB, lsu_addr)
    begin
        case lsu_addr(1 downto 0) is
            when "00" =>
                o_data_wdata <= memaccess_opB;
            when "01" =>
                o_data_wdata <= memaccess_opB(23 downto 0) & x"00";
            when "10" =>
                o_data_wdata <= memaccess_opB(15 downto 0) & x"0000";
            when "11" =>
                o_data_wdata <= memaccess_opB(7 downto 0) & x"000000";
            when others =>
                o_data_wdata <= memaccess_opB;
        end case;
    end process Aligner;

    instret <= not ctrl_cmn.stall;

    eZiCsr : entity rktcpu.ZiCsr
    port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,

        i_ctrl_zcsr => ctrl_zcsr, 
        i_opA       => memaccess_opA,
        o_csrr      => csrr,
        o_csrren    => open,
        o_csrdone   => csrdone,
        i_instret   => instret
    );

    LsuData: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                lsu_rdata  <= x"00000000";
                alu_res_ma <= x"00000000";
            else
                if (i_data_rvalid = '1') then
                    lsu_rdata  <= i_data_rdata;
                end if;
                alu_res_ma <= alu_res;
                jump_pjpc_ma <= jump_pjpc;
            end if;
        end if;
    end process LsuData;

    --------------------------------------------------------------------------------------------------------------
    -- Writeback Stage
    --------------------------------------------------------------------------------------------------------------

    WritebackResult: process(ctrl_cmn, alu_res_ma, lsu_rdata, csrr)
    begin
        if (ctrl_cmn.wb_res_sel(0) = '1') then
            writeback_res <= alu_res_ma;
        elsif (ctrl_cmn.wb_res_sel(1) = '1') then
            writeback_res <= lsu_rdata;
        elsif (ctrl_cmn.wb_res_sel(2) = '1') then
            writeback_res <= csrr;
        elsif (ctrl_cmn.wb_res_sel(3) = '1') then
            writeback_res <= jump_pjpc_ma;
        else
            writeback_res <= x"00000000";
        end if;
    end process WritebackResult;

    --------------------------------------------------------------------------------------------------------------
    -- Checks to verify implementation.
    --------------------------------------------------------------------------------------------------------------
    
end architecture rtl;