library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;
    use rktcpu.RiscVDefinitions.all;

entity ControlEngine is
    generic (
        cGenerateLoggers : boolean := false
    );
    port (
        i_clk     : in std_logic;
        i_resetn  : in std_logic;

        o_pc      : out std_logic_vector(31 downto 0);
        o_iren    : out std_logic;
        i_instr   : in std_logic_vector(31 downto 0);
        i_ivalid  : in std_logic;

        i_mvalid  : in std_logic;
        i_csrdone : in std_logic;

        o_ctrl_cmn  : out common_controls_t;
        o_ctrl_alu  : out alu_controls_t;
        o_ctrl_mem  : out mem_controls_t;
        o_ctrl_brnc : out branch_controls_t;
        o_ctrl_zcsr : out zicsr_controls_t;
        o_ctrl_jal  : out jal_controls_t;

        i_pc    : in std_logic_vector(31 downto 0);
        i_pcwen : in std_logic
    );
end entity ControlEngine;

architecture rtl of ControlEngine is
    function compute_hazards(ex_rs1, ex_rs2, 
            ma_rs1, ma_rs2, ma_rd, wb_rd : std_logic_vector(4 downto 0);
            ex_opcode, ma_opcode, wb_opcode : std_logic_vector(6 downto 0)) return std_logic_vector is
        variable hazards_rs1_ex : std_logic_vector(cMemAccessIdx to cWritebackIdx) := (others => '0');
        variable hazards_rs1_ma : std_logic := '0';
        variable hazards_rs2_ex : std_logic_vector(cMemAccessIdx to cWritebackIdx) := (others => '0');
        variable hazards_rs2_ma : std_logic := '0';
        variable induce_stall   : std_logic := '0';
    begin
        if (ex_rs1 = "00000") then
            hazards_rs1_ex(cMemAccessIdx) := '0';
        elsif (ex_rs1 = ma_rd) then
            if (ma_opcode = cLoadOpcode) then
                -- A hazard that requires an induced stall
                induce_stall := '1';
            elsif (ma_opcode = cStoreOpcode or ma_opcode = cBranchOpcode) then
                -- This is not a hazard because these do not use the rd register
                hazards_rs1_ex(cMemAccessIdx) := '0';
            else
                case ex_opcode is
                    -- These are not hazards because execute does not use the register
                    when cAuipcOpcode | cLoadUpperOpcode | cJumpOpcode =>
                        hazards_rs1_ex(cMemAccessIdx) := '0';
                    when others =>
                        hazards_rs1_ex(cMemAccessIdx) := '1';
                        hazards_rs1_ex(cWritebackIdx) := '0';
                end case;
            end if;
        end if;

        if (ex_rs1 = "00000") then
            hazards_rs1_ex(cWritebackIdx) := '0';
        elsif (ex_rs1 = wb_rd) then
            if (wb_opcode = cStoreOpcode or wb_opcode = cBranchOpcode) then
                -- This is not a hazard because these do not use the rd register
                hazards_rs1_ex(cWritebackIdx) := '0';
            else
                case ex_opcode is
                    -- These are not hazards because execute does not use the register
                    when cAuipcOpcode | cLoadUpperOpcode | cJumpOpcode =>
                        hazards_rs1_ex(cWritebackIdx) := '0';
                    when others =>
                        hazards_rs1_ex(cWritebackIdx) := '1';
                end case;
            end if;
        end if;

        if (ex_rs2 = "00000") then
            hazards_rs2_ex(cMemAccessIdx) := '0';
        elsif (ex_rs2 = ma_rd) then
            if (ma_opcode = cLoadOpcode) then
                -- A hazard that requires an induced stall
                induce_stall := '1';
            elsif (ma_opcode = cStoreOpcode or ma_opcode = cBranchOpcode) then
                -- This is not a hazard because these do not use the rd register
                hazards_rs2_ex(cMemAccessIdx) := '0';
            else
                case ex_opcode is
                    when cAuipcOpcode | cLoadUpperOpcode | cJumpOpcode | 
                            cJumpRegOpcode | cLoadOpcode | cAluImmedOpcode => 
                        hazards_rs2_ex(cMemAccessIdx) := '0';
                    when others =>
                        hazards_rs2_ex(cMemAccessIdx) := '1';
                end case;
            end if;
        end if;
        
        if (ex_rs2 = "00000") then
            hazards_rs2_ex(cWritebackIdx) := '0';
        elsif (ex_rs2 = wb_rd) then
            if (wb_opcode = cStoreOpcode or wb_opcode = cBranchOpcode) then
                -- This is not a hazard because these do not use the rd register
                hazards_rs2_ex(cWritebackIdx) := '0';
            else
                case ex_opcode is
                    when cAuipcOpcode | cLoadUpperOpcode | cJumpOpcode | 
                            cJumpRegOpcode | cLoadOpcode | cAluImmedOpcode =>
                        hazards_rs2_ex(cWritebackIdx) := '0';
                    when others =>
                        hazards_rs2_ex(cWritebackIdx) := '1';
                end case;
            end if;
        end if;

        
        return hazards_rs1_ex & hazards_rs1_ma & hazards_rs2_ex & hazards_rs2_ma & induce_stall;
    end function;

    type decoded_instr_t is record
        pc     : std_logic_vector(31 downto 0);
        opcode : std_logic_vector(6 downto 0);
        rs1    : std_logic_vector(4 downto 0);
        rs2    : std_logic_vector(4 downto 0);
        rd     : std_logic_vector(4 downto 0);
        funct3 : std_logic_vector(2 downto 0);
        funct7 : std_logic_vector(6 downto 0);
        itype  : std_logic_vector(11 downto 0);
        stype  : std_logic_vector(11 downto 0);
        btype  : std_logic_vector(12 downto 0);
        utype  : std_logic_vector(19 downto 0);
        jtype  : std_logic_vector(20 downto 0);

        valid : std_logic;
    end record decoded_instr_t;

    type instr_pipe_t is array (cDecodeIdx to cWritebackIdx) of decoded_instr_t;
    signal instr_pipe : instr_pipe_t;
    signal instr : std_logic_vector(31 downto 0) := x"00000000";
    signal stalled_instr : std_logic_vector(31 downto 0) := x"00000000";
    signal stalled_pc : unsigned(31 downto 0) := x"00000000";
    signal stalled_valid : std_logic := '0';
    signal pc : unsigned(31 downto 0) := x"00000000";
    signal fpc : unsigned(31 downto 0) := x"00000000";
    signal dpc : unsigned(31 downto 0) := x"00000000";
    signal stall : std_logic := '0';
    signal hazards_rs1 : std_logic_vector(cMemAccessIdx to cWritebackIdx) := (others => '0');
    signal hazards_rs2 : std_logic_vector(cMemAccessIdx to cWritebackIdx) := (others => '0');
    signal alu_res_sel : std_logic_vector(3 downto 0) := "0000";
    signal hazards_rs1_ma : std_logic := '0';
    signal hazards_rs2_ma : std_logic := '0';
    signal wb_res_sel     : std_logic_vector(3 downto 0) := "0000";
    signal ivalid         : std_logic := '0';
    signal induced_stall  : std_logic := '0';
    signal awaited_mvalid : std_logic := '0';
begin

    o_pc <= std_logic_vector(pc);

    Engine: process(i_clk)
        variable awaiting_csrdone : std_logic;
        variable awaiting_mvalid  : std_logic;
        variable stall_v          : std_logic;

        variable hazards : std_logic_vector(0 to 6);
        variable induce_stall : std_logic := '0';
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                pc     <= x"00000000";
                fpc    <= x"00000000";
                o_iren <= '0';
                instr  <= x"00000000";
                ivalid <= '0';
                for ii in cDecodeIdx to cWritebackIdx loop
                    instr_pipe(ii) <= (
                        pc     => x"00000000",
                        opcode => "0000000",
                        rs1    => "00000",
                        rs2    => "00000",
                        rd     => "00000",
                        funct3 => "000",
                        funct7 => "0000000",
                        itype  => x"000",
                        stype  => x"000",
                        btype  => '0' & x"000",
                        utype  => x"00000",
                        jtype  => '0' & x"00000",
                        valid  => '0'
                    );
                end loop;
            else
                o_iren <= '1';
                if (i_pcwen = '1') then
                    pc <= unsigned(i_pc);

                    fpc    <= x"00000000";
                    dpc    <= x"00000000";
                    instr  <= x"00000000";
                    ivalid <= '0';
                    for ii in cDecodeIdx to cMemAccessIdx loop
                        instr_pipe(ii) <= (
                            pc     => x"00000000",
                            opcode => "0000000",
                            rs1    => "00000",
                            rs2    => "00000",
                            rd     => "00000",
                            funct3 => "000",
                            funct7 => "0000000",
                            itype  => x"000",
                            stype  => x"000",
                            btype  => '0' & x"000",
                            utype  => x"00000",
                            jtype  => '0' & x"00000",
                            valid  => '0'
                        );
                    end loop;
                    instr_pipe(cWritebackIdx) <= instr_pipe(cMemAccessIdx);
                else
                    -- Go ahead and compute the current hazards, as well as if a stall needs to be induced.
                    -- An induced stall is placed in the execute stage, thereby allowing the data from the
                    -- decode stage to stall.
                    hazards := compute_hazards(
                        instr_pipe(cDecodeIdx).rs1,
                        instr_pipe(cDecodeIdx).rs2,
                        instr_pipe(cExecuteIdx).rs1,
                        instr_pipe(cExecuteIdx).rs2,
                        instr_pipe(cExecuteIdx).rd,
                        instr_pipe(cMemAccessIdx).rd,
                        instr_pipe(cDecodeIdx).opcode,
                        instr_pipe(cExecuteIdx).opcode,
                        instr_pipe(cMemAccessIdx).opcode
                    );

                    -- Split the hazards based on internal structure to connect to all required signals.
                    hazards_rs1    <= hazards(0 to 1);
                    hazards_rs1_ma <= hazards(2);
                    hazards_rs2    <= hazards(3 to 4);
                    hazards_rs2_ma <= hazards(5);
                    induce_stall   := hazards(6);
                    induced_stall  <= induce_stall;
                    awaited_mvalid <= awaiting_mvalid;

                    -- Check to see if we're waiting for a CSR instruction to complete.
                    awaiting_csrdone := bool2bit(instr_pipe(cMemAccessIdx).opcode = cEcallOpcode and 
                        instr_pipe(cMemAccessIdx).funct3 /= "000");
                    -- Check to see if we're waiting for a Load instruction to complete.
                    awaiting_mvalid := bool2bit(instr_pipe(cMemAccessIdx).opcode = cLoadOpcode);

                    -- If we're waiting on memory, a CSR, or an instruction, or maybe just creating a stall, stall.
                    stall_v := bool2bit(i_ivalid = '0' or induce_stall = '1' or (i_mvalid = '0' and awaiting_mvalid = '1') 
                        or (i_csrdone = '0' and awaiting_csrdone = '1'));
                    stall <= stall_v;

                    -- In order to prevent an instruction from being dropped, lower the instruction read enable signal.
                    o_iren <= not induce_stall;

                    -- If we're not stalled, then continue to process instructions.
                    if (stall_v = '0') then
                        pc  <= pc + 4;
                        fpc <= pc;
                        
                        if (stalled_valid = '0') then
                            instr <= i_instr;
                            dpc   <= fpc;
                        else
                            instr         <= stalled_instr;
                            dpc           <= stalled_pc;
                            stalled_valid <= '0';
                        end if;

                        -- Decode
                        instr_pipe(cDecodeIdx).pc     <= std_logic_vector(dpc);
                        instr_pipe(cDecodeIdx).opcode <= get_opcode(instr);
                        instr_pipe(cDecodeIdx).rd     <= get_rd(instr);
                        instr_pipe(cDecodeIdx).rs1    <= get_rs1(instr);
                        instr_pipe(cDecodeIdx).rs2    <= get_rs2(instr);
                        instr_pipe(cDecodeIdx).funct3 <= get_funct3(instr);
                        instr_pipe(cDecodeIdx).funct7 <= get_funct7(instr);
                        instr_pipe(cDecodeIdx).itype  <= get_itype(instr);
                        instr_pipe(cDecodeIdx).stype  <= get_stype(instr);
                        instr_pipe(cDecodeIdx).btype  <= get_btype(instr);
                        instr_pipe(cDecodeIdx).utype  <= get_utype(instr);
                        instr_pipe(cDecodeIdx).jtype  <= get_jtype(instr);
                        instr_pipe(cDecodeIdx).valid  <= '1';

                        -- Execute through Writeback
                        for ii in cDecodeIdx to cMemAccessIdx loop
                            instr_pipe(ii + 1) <= instr_pipe(ii);
                        end loop;
                    else
                        if (induce_stall = '1') then
                            instr_pipe(cWritebackIdx) <= instr_pipe(cMemAccessIdx);
                            instr_pipe(cMemAccessIdx) <= instr_pipe(cExecuteIdx);
                            instr_pipe(cExecuteIdx) <= (
                                    pc     => x"00000000",
                                    opcode => cAluImmedOpcode,
                                    rs1    => "00000",
                                    rs2    => "00000",
                                    rd     => "00000",
                                    funct3 => "000",
                                    funct7 => "0000000",
                                    itype  => x"000",
                                    stype  => x"000",
                                    btype  => '0' & x"000",
                                    utype  => x"00000",
                                    jtype  => '0' & x"00000",
                                    valid  => '0'
                            );

                            -- If we induce a stall, we may never actually use the
                            -- most recently returned instruction from the 
                            -- instruction memory. This saves the last instruction
                            -- (if there is any) to preserve for after the stall.
                            if (i_ivalid = '1') then
                                fpc           <= pc;
                                stalled_instr <= i_instr;
                                stalled_pc    <= fpc;
                                stalled_valid <= '1';
                            end if;
                        else
                            -- If we're stalled, writeback is already done so we don't
                            -- need to worry about stalling it during this stage.
                            -- Allow it to be replaced with an invalid NOP.
                            instr_pipe(cWritebackIdx) <= (
                                    pc     => x"00000000",
                                    opcode => cAluImmedOpcode,
                                    rs1    => "00000",
                                    rs2    => "00000",
                                    rd     => "00000",
                                    funct3 => "000",
                                    funct7 => "0000000",
                                    itype  => x"000",
                                    stype  => x"000",
                                    btype  => '0' & x"000",
                                    utype  => x"00000",
                                    jtype  => '0' & x"00000",
                                    valid  => '0'
                                );
                            if (instr_pipe(cMemAccessIdx).opcode = cLoadOpcode) then
                                if (i_mvalid = '1') then
                                    instr_pipe(cWritebackIdx) <= instr_pipe(cMemAccessIdx);
                                    instr_pipe(cMemAccessIdx) <= (
                                        pc     => x"00000000",
                                        opcode => cAluImmedOpcode,
                                        rs1    => "00000",
                                        rs2    => "00000",
                                        rd     => "00000",
                                        funct3 => "000",
                                        funct7 => "0000000",
                                        itype  => x"000",
                                        stype  => x"000",
                                        btype  => '0' & x"000",
                                        utype  => x"00000",
                                        jtype  => '0' & x"00000",
                                        valid  => '0'
                                    );
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process Engine;

    -- Common Controls
    o_ctrl_cmn.rs1        <= instr_pipe(cDecodeIdx).rs1;
    o_ctrl_cmn.rs2        <= instr_pipe(cDecodeIdx).rs2;

    o_ctrl_cmn.hzd_rs1_ex <= hazards_rs1;
    o_ctrl_cmn.hzd_rs2_ex <= hazards_rs2;
    o_ctrl_cmn.hzd_rs1_ma <= hazards_rs1_ma;
    o_ctrl_cmn.hzd_rs2_ma <= hazards_rs2_ma;
    o_ctrl_cmn.upper      <= bool2bit(instr_pipe(cExecuteIdx).opcode = cLoadUpperOpcode);
    o_ctrl_cmn.auipc      <= bool2bit(instr_pipe(cExecuteIdx).opcode = cAuipcOpcode);
    o_ctrl_cmn.iimmed     <= bool2bit(instr_pipe(cExecuteIdx).opcode = cAluImmedOpcode);
    o_ctrl_cmn.itype      <= instr_pipe(cExecuteIdx).itype;
    o_ctrl_cmn.utype      <= instr_pipe(cExecuteIdx).utype;
    o_ctrl_cmn.btype      <= instr_pipe(cExecuteIdx).btype;
    o_ctrl_cmn.stype      <= instr_pipe(cExecuteIdx).stype;
    o_ctrl_cmn.store      <= bool2bit(instr_pipe(cExecuteIdx).opcode = cStoreOpcode);
    o_ctrl_cmn.jtype      <= instr_pipe(cExecuteIdx).jtype;
    o_ctrl_cmn.stall      <= stall;
    o_ctrl_cmn.pc         <= instr_pipe(cExecuteIdx).pc;
    o_ctrl_cmn.wb_res_sel <= wb_res_sel;
    o_ctrl_cmn.rd         <= instr_pipe(cWritebackIdx).rd;
    o_ctrl_cmn.rdwen      <= bool2bit((instr_pipe(cWritebackIdx).opcode = cAluOpcode or 
        instr_pipe(cWritebackIdx).opcode = cJumpRegOpcode or 
        instr_pipe(cWritebackIdx).opcode = cAluImmedOpcode or 
        instr_pipe(cWritebackIdx).opcode = cJumpOpcode or
        instr_pipe(cWritebackIdx).opcode = cLoadUpperOpcode or
        instr_pipe(cWritebackIdx).opcode = cAuipcOpcode or
        instr_pipe(cWritebackIdx).opcode = cLoadOpcode) and instr_pipe(cWritebackIdx).rd /= "00000");

    wb_res_sel(0) <= bool2bit(instr_pipe(cWritebackIdx).opcode = cAluOpcode or 
        instr_pipe(cWritebackIdx).opcode = cAluImmedOpcode or
        instr_pipe(cWritebackIdx).opcode = cAuipcOpcode or
        instr_pipe(cWritebackIdx).opcode = cLoadUpperOpcode);
    wb_res_sel(1) <= bool2bit(instr_pipe(cWritebackIdx).opcode = cLoadOpcode);
    wb_res_sel(2) <= bool2bit(instr_pipe(cWritebackIdx).opcode = cEcallOpcode and
        instr_pipe(cWritebackIdx).funct3 /= "000");
    wb_res_sel(3) <= bool2bit(instr_pipe(cWritebackIdx).opcode = cJumpOpcode or
        instr_pipe(cWritebackIdx).opcode = cJumpRegOpcode);

    -- ALU Controls
    o_ctrl_alu.addn <= (instr_pipe(cExecuteIdx).funct7(5) and instr_pipe(cExecuteIdx).opcode(5))  -- This performs subtraction.
        and not (bool2bit(instr_pipe(cExecuteIdx).opcode = cLoadUpperOpcode or instr_pipe(cExecuteIdx).opcode = cAuipcOpcode));

    o_ctrl_alu.funct3 <= instr_pipe(cMemAccessIdx).funct3;

    alu_res_sel <= bool2bit(instr_pipe(cMemAccessIdx).funct3 = "000" or instr_pipe(cMemAccessIdx).opcode = cLoadUpperOpcode or instr_pipe(cMemAccessIdx).opcode = cAuipcOpcode) 
        & bool2bit(instr_pipe(cMemAccessIdx).funct3 = "100" or instr_pipe(cMemAccessIdx).funct3 = "110" or instr_pipe(cMemAccessIdx).funct3 = "111") 
        & bool2bit(instr_pipe(cMemAccessIdx).funct3 = "001" or instr_pipe(cMemAccessIdx).funct3 = "101")
        & bool2bit(instr_pipe(cMemAccessIdx).funct3 = "010" or instr_pipe(cMemAccessIdx).funct3 = "011");

    o_ctrl_alu.res_sel <= alu_res_sel;
    o_ctrl_alu.sright  <= instr_pipe(cExecuteIdx).funct3(2);
    o_ctrl_alu.sarith  <= instr_pipe(cExecuteIdx).funct7(5);
    o_ctrl_alu.slt     <= not instr_pipe(cExecuteIdx).funct3(2) and instr_pipe(cExecuteIdx).funct3(1);
    o_ctrl_alu.sltuns  <= instr_pipe(cExecuteIdx).funct3(0);

    -- Branch Controls
    o_ctrl_brnc.en  <= bool2bit(instr_pipe(cMemAccessIdx).opcode = cBranchOpcode);
    o_ctrl_brnc.blt <= instr_pipe(cMemAccessIdx).funct3(2);
    o_ctrl_brnc.uns <= instr_pipe(cMemAccessIdx).funct3(1);
    o_ctrl_brnc.inv <= instr_pipe(cMemAccessIdx).funct3(0);

    -- Memory Controls
    o_ctrl_mem.en         <= bool2bit(instr_pipe(cMemAccessIdx).opcode = cStoreOpcode or instr_pipe(cMemAccessIdx).opcode = cLoadOpcode); 
    o_ctrl_mem.store      <= bool2bit(instr_pipe(cMemAccessIdx).opcode = cStoreOpcode);
    o_ctrl_mem.write_type <= instr_pipe(cMemAccessIdx).funct3;

    -- Jump Controls
    o_ctrl_jal.en <= bool2bit(instr_pipe(cMemAccessIdx).opcode = cJumpOpcode or
        instr_pipe(cMemAccessIdx).opcode = cJumpRegOpcode);
    o_ctrl_jal.jalr <= bool2bit(instr_pipe(cExecuteIdx).opcode = cJumpRegOpcode);

    InstructionPipeChecker: process(instr_pipe)
        variable lhpc : std_logic_vector(31 downto 0) := x"00000000";
        variable rhpc : std_logic_vector(31 downto 0) := x"00000000";
        variable cc   : natural := 0;
    begin
        report "Starting cycle " & integer'image(cc);
        for ii in cDecodeIdx to cMemAccessIdx loop
            if (instr_pipe(ii).valid = '1') then
                lhpc := instr_pipe(ii).pc;
                if (instr_pipe(ii + 1).valid = '1') then
                    rhpc := instr_pipe(ii + 1).pc;
                    report to_hstring(lhpc) & "," & to_hstring(rhpc);
                    --assert unsigned(lhpc) = unsigned(rhpc) + 4;
                end if;
            end if;
        end loop;
        cc := cc + 1;
    end process InstructionPipeChecker;

end architecture rtl;