library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RiscVDefinitions.all;

package RktCpuDefinitions is

    constant cFetchIdx     : natural := 0;
    constant cDecodeIdx    : natural := 1;
    constant cExecuteIdx   : natural := 2;
    constant cMemAccessIdx : natural := 3;
    constant cWritebackIdx : natural := 4;

    type stage_t is record
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
    end record stage_t;

    type stages_t is array (cFetchIdx to cWritebackIdx) of stage_t;

    function is_rs2_valid(stage : stage_t) return boolean;

    function is_rs1_valid(stage : stage_t) return boolean;

    function is_rd_valid(stage : stage_t) return boolean;

    function induce_stall(stage0 : stage_t) return std_logic;

    function identify_hazards(stage0, stage1, stage2 : stage_t) return std_logic_vector;

    procedure advance(
        -- current pipeline state
        signal io_stages  : inout stages_t;
        -- indicator that data arrived from memory
        signal i_mvalid  : in std_logic;
        -- indicator that csr access completed
        signal i_csrdone : in std_logic;
        -- current instr address
        signal i_dpc : in std_logic_vector(31 downto 0);
        -- current instr data
        signal i_instr : in std_logic_vector(31 downto 0);
        -- indicator that the current instr data is valid
        signal i_dvalid  : in std_logic;
        -- indicator that a stall needs to be induced
        signal i_istall : in std_logic;
        -- indicator that new instr data arrived
        variable io_stall : inout std_logic
    );

    type alu_controls_t is record
        addn    : std_logic;
        res_sel : std_logic_vector(3 downto 0);
        funct3  : std_logic_vector(2 downto 0);
        sright  : std_logic;
        sarith  : std_logic;
        slt     : std_logic;
        sltuns  : std_logic;
    end record alu_controls_t;

    type common_controls_t is record
        rs1        : std_logic_vector(4 downto 0);
        rs2        : std_logic_vector(4 downto 0);
        rd         : std_logic_vector(4 downto 0);
        rdwen      : std_logic;
        hzd_rs1_ex : std_logic_vector(cMemAccessIdx to cWritebackIdx);
        hzd_rs2_ex : std_logic_vector(cMemAccessIdx to cWritebackIdx);
        hzd_rs1_ma : std_logic;
        hzd_rs2_ma : std_logic;
        pc         : std_logic_vector(31 downto 0);
        auipc      : std_logic;
        iimmed     : std_logic;
        itype      : std_logic_vector(11 downto 0);
        store      : std_logic;
        stype      : std_logic_vector(11 downto 0);
        btype      : std_logic_vector(12 downto 0);
        upper      : std_logic;
        utype      : std_logic_vector(19 downto 0);
        jtype      : std_logic_vector(20 downto 0);
        stall      : std_logic;
        wb_res_sel : std_logic_vector(3 downto 0);
    end record common_controls_t;
    
    type mem_controls_t is record
        en         : std_logic;
        store      : std_logic;
        write_type : std_logic_vector(2 downto 0);
    end record mem_controls_t;

    type jal_controls_t is record
        en   : std_logic;
        jalr : std_logic;
    end record jal_controls_t;

    type branch_controls_t is record
        en  : std_logic;
        blt : std_logic;
        uns : std_logic;
        inv : std_logic;
    end record branch_controls_t;

    type zicsr_controls_t is record
        en     : std_logic;
        rs1    : std_logic_vector(4 downto 0);
        rs2    : std_logic_vector(4 downto 0);
        rd     : std_logic_vector(4 downto 0);
        funct3 : std_logic_vector(2 downto 0);
        itype  : std_logic_vector(11 downto 0);
        mret   : std_logic;
        sret   : std_logic;
        pc     : std_logic_vector(31 downto 0);
    end record zicsr_controls_t;

    type dbg_controls_t is record
        pc       : std_logic_vector(31 downto 0);
        mapc     : std_logic_vector(31 downto 0);
        valid    : std_logic;
    end record dbg_controls_t;
    
end package RktCpuDefinitions;

package body RktCpuDefinitions is
    
    function is_rs2_valid(stage : stage_t) return boolean is
    begin
        case stage.opcode is
            when cBranchOpcode | cStoreOpcode | cAluOpcode =>
                return true;
            when others =>
                return false;
        end case;
    end function;

    function is_rs1_valid(stage : stage_t) return boolean is
    begin
        case stage.opcode is
            when cLoadUpperOpcode | cAuipcOpcode | cJumpOpcode =>
                return false;
            when cEcallOpcode =>
                return stage.funct3 /= "000";
            when others =>
                return true;
        end case;
    end function;

    function is_rd_valid(stage : stage_t) return boolean is
    begin
        case stage.opcode is
            when cBranchOpcode | cStoreOpcode =>
                return false;
            when cEcallOpcode =>
                return stage.funct3 /= "000";
            when others =>
                return true;
        end case;
    end function;

    function induce_stall(stage0 : stage_t) return std_logic is
    begin
        if (stage0.opcode = cLoadOpcode or 
            (stage0.opcode = cEcallOpcode and stage0.funct3 /= "000")) then
            return '1';
        end if;
        return '0';
    end function;

    function identify_hazards(stage0, stage1, stage2 : stage_t) return std_logic_vector is
        variable hazards_rs1 : std_logic_vector(0 to 1) := "00";
        variable hazards_rs2 : std_logic_vector(0 to 1) := "00";
    begin
        if ((stage0.rs1 = stage1.rd) and 
                (to_natural(stage1.rd) /= 0) and 
                is_rs1_valid(stage0) and 
                is_rd_valid(stage1)) then
            hazards_rs1 := "10";            
        elsif ((stage0.rs1 = stage2.rd) and 
                (to_natural(stage2.rd) /= 0) and 
                is_rs1_valid(stage0) and 
                is_rd_valid(stage1)) then
            hazards_rs1 := "01";
        end if;

        if ((stage0.rs2 = stage1.rd) and 
                (to_natural(stage1.rd) /= 0) and 
                is_rs2_valid(stage0) and 
                is_rd_valid(stage1)) then
            hazards_rs2 := "10";            
        elsif ((stage0.rs2 = stage2.rd) and 
                (to_natural(stage2.rd) /= 0) and 
                is_rs2_valid(stage0) and 
                is_rd_valid(stage2)) then
            hazards_rs2 := "01";
        end if;

        return hazards_rs1 & hazards_rs2;
    end function;

    procedure advance(
        -- current pipeline state
        signal io_stages  : inout stages_t;
        -- indicator that data arrived from memory
        signal i_mvalid  : in std_logic;
        -- indicator that csr access completed
        signal i_csrdone : in std_logic;
        -- current instr address
        signal i_dpc : in std_logic_vector(31 downto 0);
        -- current instr data
        signal i_instr : in std_logic_vector(31 downto 0);
        -- indicator that the current instr data is valid
        signal i_dvalid  : in std_logic;
        -- indicator that a stall needs to be induced
        signal i_istall : in std_logic;
        -- indicator that new instr data arrived
        variable io_stall : inout std_logic
    ) is
    begin
        -- If we're not getting something we need to advance, we need to stop the
        -- entire rest of the pipeline. Writeback can finish, but everything else
        -- must stop.
        io_stall := '0';
        if ((i_mvalid = '0' and ((io_stages(cMemAccessIdx).opcode = cLoadOpcode) or
                (io_stages(cMemAccessIdx).opcode = cStoreOpcode))) or 
                (i_csrdone = '0' and io_stages(cMemAccessIdx).opcode = cEcallOpcode and 
                    io_stages(cMemAccessIdx).funct3 /= "000")) then
            io_stages(cWritebackIdx) <= (
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
            io_stall := '1';
        else
            -- Otherwise, advance the instruction currently in MemAccess.
            io_stages(cWritebackIdx) <= io_stages(cMemAccessIdx);
        end if;

        -- If we're not otherwise stalled, advance the instruction in Execute
        if (io_stall = '0') then
            io_stages(cMemAccessIdx) <= io_stages(cExecuteIdx);
        end if;

        -- If we're not otherwise stalled, advance the instruction in decode,
        -- as well as fetch as long as no stalls have been induced.
        if (io_stall = '0') then
            io_stages(cExecuteIdx) <= io_stages(cDecodeIdx);
            if (i_istall = '1') then
                io_stages(cDecodeIdx) <= (
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
                io_stall := '1';
            else
                io_stages(cDecodeIdx) <= io_stages(cFetchIdx);
            end if;
        end if;

        if ((i_dvalid and not io_stall) = '1') then
            io_stages(cFetchIdx).pc     <= i_dpc;
            io_stages(cFetchIdx).opcode <= get_opcode(i_instr);
            io_stages(cFetchIdx).rd     <= get_rd(i_instr);
            io_stages(cFetchIdx).rs1    <= get_rs1(i_instr);
            io_stages(cFetchIdx).rs2    <= get_rs2(i_instr);
            io_stages(cFetchIdx).funct3 <= get_funct3(i_instr);
            io_stages(cFetchIdx).funct7 <= get_funct7(i_instr);
            io_stages(cFetchIdx).itype  <= get_itype(i_instr);
            io_stages(cFetchIdx).stype  <= get_stype(i_instr);
            io_stages(cFetchIdx).btype  <= get_btype(i_instr);
            io_stages(cFetchIdx).utype  <= get_utype(i_instr);
            io_stages(cFetchIdx).jtype  <= get_jtype(i_instr);
            io_stages(cFetchIdx).valid  <= i_dvalid;
        elsif (((not i_dvalid) and (not io_stall)) = '1') then
            io_stages(cFetchIdx) <= (
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
        end if;
    end procedure;
    
end package body RktCpuDefinitions;