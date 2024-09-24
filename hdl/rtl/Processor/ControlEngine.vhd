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
        o_ctrl_dbg  : out dbg_controls_t;

        i_pc      : in std_logic_vector(31 downto 0);
        i_pcwen   : in std_logic;
        i_irvalid : in std_logic
    );
end entity ControlEngine;

architecture rtl of ControlEngine is
    signal pipeline : stages_t;
    
    signal rpc    : std_logic_vector(31 downto 0) := x"00000000";
    signal instr  : std_logic_vector(31 downto 0) := x"00000000";
    signal ivalid : std_logic := '0';
    signal iren   : std_logic := '0';
    signal req    : std_logic := '0';

    signal hazards_rs1    : std_logic_vector(cMemAccessIdx to cWritebackIdx) := (others => '0');
    signal hazards_rs2    : std_logic_vector(cMemAccessIdx to cWritebackIdx) := (others => '0');
    signal alu_res_sel    : std_logic_vector(3 downto 0) := "0000";
    signal hazards_rs1_ma : std_logic := '0';
    signal hazards_rs2_ma : std_logic := '0';
    signal wb_res_sel     : std_logic_vector(3 downto 0) := "0000";
    signal induced_stall  : std_logic := '0';
begin

    o_iren <= iren and not i_pcwen;

    eFetch : entity rktcpu.FetchEngine
    port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,

        o_pc    => o_pc,
        o_iren  => iren,
        i_stall => induced_stall,
        o_rpc   => rpc,

        i_pcwen => i_pcwen,
        i_pc    => i_pc
    );

    Engine: process(i_clk)
        variable stall   : std_logic := '0';
        variable hazards : std_logic_vector(0 to 3);
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                for ii in cFetchIdx to cWritebackIdx loop
                    pipeline(ii) <= (
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
                end loop;
            else
                -- If a pc write occurs, then none of the current instructions that arent in 
                -- writeback or possibly memaccess matter.
                if (i_pcwen = '1') then
                    for ii in cFetchIdx to cMemAccessIdx loop
                        pipeline(ii) <= (
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
                    pipeline(cWritebackIdx) <= pipeline(cMemAccessIdx);

                elsif (i_irvalid = '1') then
                    assert False report "Not implemented yet!!!" severity error;
                else
                    hazards       := identify_hazards(pipeline(cDecodeIdx), pipeline(cExecuteIdx), pipeline(cMemAccessIdx));
                    hazards_rs1   <= hazards(0 to 1);
                    hazards_rs2   <= hazards(2 to 3);
                    induced_stall <= induce_stall(pipeline(0), pipeline(1));

                    advance(
                        io_stages  => pipeline,
                        i_mvalid   => i_mvalid,
                        i_csrdone  => i_csrdone,
                        i_dpc      => rpc,
                        i_instr    => i_instr,
                        i_dvalid   => i_ivalid,
                        i_istall   => induced_stall,
                        io_stall   => stall
                    );

                    -- Verify that i_ivalid and stall are never the same value.
                    --assert (not ((i_ivalid and stall) = '1'));
                end if;
            end if;
        end if;
    end process Engine;

    -- Common Controls
    o_ctrl_cmn.rs1        <= pipeline(cDecodeIdx).rs1;
    o_ctrl_cmn.rs2        <= pipeline(cDecodeIdx).rs2;

    o_ctrl_cmn.hzd_rs1_ex <= hazards_rs1;
    o_ctrl_cmn.hzd_rs2_ex <= hazards_rs2;
    o_ctrl_cmn.hzd_rs1_ma <= hazards_rs1_ma;
    o_ctrl_cmn.hzd_rs2_ma <= hazards_rs2_ma;
    o_ctrl_cmn.upper      <= bool2bit(pipeline(cExecuteIdx).opcode = cLoadUpperOpcode);
    o_ctrl_cmn.auipc      <= bool2bit(pipeline(cExecuteIdx).opcode = cAuipcOpcode);
    o_ctrl_cmn.iimmed     <= bool2bit(pipeline(cExecuteIdx).opcode = cAluImmedOpcode);
    o_ctrl_cmn.itype      <= pipeline(cExecuteIdx).itype;
    o_ctrl_cmn.utype      <= pipeline(cExecuteIdx).utype;
    o_ctrl_cmn.btype      <= pipeline(cExecuteIdx).btype;
    o_ctrl_cmn.stype      <= pipeline(cExecuteIdx).stype;
    o_ctrl_cmn.store      <= bool2bit(pipeline(cExecuteIdx).opcode = cStoreOpcode);
    o_ctrl_cmn.jtype      <= pipeline(cExecuteIdx).jtype;
    o_ctrl_cmn.stall      <= '0';
    o_ctrl_cmn.pc         <= pipeline(cExecuteIdx).pc;
    o_ctrl_cmn.wb_res_sel <= wb_res_sel;
    o_ctrl_cmn.rd         <= pipeline(cWritebackIdx).rd;
    o_ctrl_cmn.rdwen      <= bool2bit((pipeline(cWritebackIdx).opcode = cAluOpcode or 
        pipeline(cWritebackIdx).opcode = cJumpRegOpcode or 
        pipeline(cWritebackIdx).opcode = cAluImmedOpcode or 
        pipeline(cWritebackIdx).opcode = cJumpOpcode or
        pipeline(cWritebackIdx).opcode = cLoadUpperOpcode or
        pipeline(cWritebackIdx).opcode = cAuipcOpcode or
        pipeline(cWritebackIdx).opcode = cLoadOpcode) and pipeline(cWritebackIdx).rd /= "00000");

    wb_res_sel(0) <= bool2bit(pipeline(cWritebackIdx).opcode = cAluOpcode or 
        pipeline(cWritebackIdx).opcode = cAluImmedOpcode or
        pipeline(cWritebackIdx).opcode = cAuipcOpcode or
        pipeline(cWritebackIdx).opcode = cLoadUpperOpcode);
    wb_res_sel(1) <= bool2bit(pipeline(cWritebackIdx).opcode = cLoadOpcode);
    wb_res_sel(2) <= bool2bit(pipeline(cWritebackIdx).opcode = cEcallOpcode and
        pipeline(cWritebackIdx).funct3 /= "000");
    wb_res_sel(3) <= bool2bit(pipeline(cWritebackIdx).opcode = cJumpOpcode or
        pipeline(cWritebackIdx).opcode = cJumpRegOpcode);

    -- ALU Controls
    o_ctrl_alu.addn <= (pipeline(cExecuteIdx).funct7(5) and pipeline(cExecuteIdx).opcode(5))  -- This performs subtraction.
        and not (bool2bit(pipeline(cExecuteIdx).opcode = cLoadUpperOpcode or pipeline(cExecuteIdx).opcode = cAuipcOpcode));

    o_ctrl_alu.funct3 <= pipeline(cMemAccessIdx).funct3;

    alu_res_sel <= bool2bit(pipeline(cMemAccessIdx).funct3 = "000" or pipeline(cMemAccessIdx).opcode = cLoadUpperOpcode or pipeline(cMemAccessIdx).opcode = cAuipcOpcode) 
        & bool2bit(pipeline(cMemAccessIdx).funct3 = "100" or pipeline(cMemAccessIdx).funct3 = "110" or pipeline(cMemAccessIdx).funct3 = "111") 
        & bool2bit(pipeline(cMemAccessIdx).funct3 = "001" or pipeline(cMemAccessIdx).funct3 = "101")
        & bool2bit(pipeline(cMemAccessIdx).funct3 = "010" or pipeline(cMemAccessIdx).funct3 = "011");

    o_ctrl_alu.res_sel <= alu_res_sel;
    o_ctrl_alu.sright  <= pipeline(cExecuteIdx).funct3(2);
    o_ctrl_alu.sarith  <= pipeline(cExecuteIdx).funct7(5);
    o_ctrl_alu.slt     <= not pipeline(cExecuteIdx).funct3(2) and pipeline(cExecuteIdx).funct3(1);
    o_ctrl_alu.sltuns  <= pipeline(cExecuteIdx).funct3(0);

    -- Branch Controls
    o_ctrl_brnc.en  <= bool2bit(pipeline(cMemAccessIdx).opcode = cBranchOpcode);
    o_ctrl_brnc.blt <= pipeline(cMemAccessIdx).funct3(2);
    o_ctrl_brnc.uns <= pipeline(cMemAccessIdx).funct3(1);
    o_ctrl_brnc.inv <= pipeline(cMemAccessIdx).funct3(0);

    -- Memory Controls
    o_ctrl_mem.en         <= bool2bit(pipeline(cMemAccessIdx).opcode = cStoreOpcode or pipeline(cMemAccessIdx).opcode = cLoadOpcode); 
    o_ctrl_mem.store      <= bool2bit(pipeline(cMemAccessIdx).opcode = cStoreOpcode);
    o_ctrl_mem.write_type <= pipeline(cMemAccessIdx).funct3;

    -- Jump Controls
    o_ctrl_jal.en <= bool2bit(pipeline(cMemAccessIdx).opcode = cJumpOpcode or
        pipeline(cMemAccessIdx).opcode = cJumpRegOpcode);
    o_ctrl_jal.jalr <= bool2bit(pipeline(cExecuteIdx).opcode = cJumpRegOpcode);

    -- Zicsr Controls
    o_ctrl_zcsr.en <= bool2bit(pipeline(cMemAccessIdx).opcode = cEcallOpcode and 
        pipeline(cMemAccessIdx).funct3 /= "000" and pipeline(cMemAccessIdx).funct3 /= "100");
    o_ctrl_zcsr.funct3 <= pipeline(cMemAccessIdx).funct3;
    o_ctrl_zcsr.itype  <= pipeline(cMemAccessIdx).itype;
    o_ctrl_zcsr.rs1    <= pipeline(cMemAccessIdx).rs1;
    o_ctrl_zcsr.rs2    <= pipeline(cMemAccessIdx).rs2;
    o_ctrl_zcsr.rd     <= pipeline(cMemAccessIdx).rd;
    o_ctrl_zcsr.mret   <= bool2bit(pipeline(cMemAccessIdx).opcode = cEcallOpcode and 
        pipeline(cMemAccessIdx).funct3 = "000" and pipeline(cMemAccessIdx).rs1 = "00000" and
        pipeline(cMemAccessIdx).rs2 = "00010" and pipeline(cMemAccessIdx).rd = "00000" and 
        pipeline(cMemAccessIdx).funct7 = "0011000");
    o_ctrl_zcsr.pc <= pipeline(cMemAccessIdx).pc;

    o_ctrl_dbg.pc    <= pipeline(cWritebackIdx).pc;
    o_ctrl_dbg.mapc  <= pipeline(cMemAccessIdx).pc;
    o_ctrl_dbg.valid <= pipeline(cWritebackIdx).valid;

    InstructionPipeChecker: process(pipeline)
        variable lhpc : std_logic_vector(31 downto 0) := x"00000000";
        variable rhpc : std_logic_vector(31 downto 0) := x"00000000";
        variable cc   : natural := 0;
    begin
        report "Starting cycle " & integer'image(cc);
        for ii in cDecodeIdx to cMemAccessIdx loop
            if (pipeline(ii).valid = '1') then
                lhpc := pipeline(ii).pc;
                if (pipeline(ii + 1).valid = '1') then
                    rhpc := pipeline(ii + 1).pc;
                    report to_hstring(lhpc) & "," & to_hstring(rhpc);
                    --assert unsigned(lhpc) = unsigned(rhpc) + 4;
                end if;
            end if;
        end loop;
        cc := cc + 1;
    end process InstructionPipeChecker;

end architecture rtl;