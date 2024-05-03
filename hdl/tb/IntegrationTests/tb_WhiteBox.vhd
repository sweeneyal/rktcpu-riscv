library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.RiscVDefinitions.all;
    use scrv.ControlEntities.all;
    use scrv.DataPathEntities.all;

library tb;
    use tb.UvmTbPeripherals.all;

entity tb_WhiteBox is
    generic (runner_cfg : string);
end entity tb_WhiteBox;

architecture tb of tb_WhiteBox is
    -- System level signals
    signal i_clk    : std_logic;
    signal i_resetn : std_logic;

    -- Bus Signals
    signal instr_addr   : std_logic_vector(31 downto 0) := (others => '0');
    signal instr_ren    : std_logic := '0';
    signal instr_wen    : std_logic_vector(3 downto 0) := (others => '0');
    signal instr_wdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal instr_rdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal instr_rvalid : std_logic := '0';

    -- Bus Signals
    signal data_addr   : std_logic_vector(31 downto 0);
    signal data_ren    : std_logic;
    signal data_wen    : std_logic_vector(3 downto 0);
    signal data_wdata  : std_logic_vector(31 downto 0);
    signal data_rdata  : std_logic_vector(31 downto 0);
    signal data_rvalid : std_logic;

    -- Datapath Signals
    signal dpath_pc     : std_logic_vector(31 downto 0) := (others => '0');
    signal dpath_opcode : std_logic_vector(6 downto 0) := (others => '0');
    signal dpath_rs1    : std_logic_vector(4 downto 0) := (others => '0');
    signal dpath_rs2    : std_logic_vector(4 downto 0) := (others => '0');
    signal dpath_rd     : std_logic_vector(4 downto 0) := (others => '0');
    signal dpath_funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal dpath_funct7 : std_logic_vector(6 downto 0) := (others => '0');
    signal dpath_itype  : std_logic_vector(11 downto 0) := (others => '0');
    signal dpath_stype  : std_logic_vector(11 downto 0) := (others => '0');
    signal dpath_btype  : std_logic_vector(12 downto 0) := (others => '0');
    signal dpath_utype  : std_logic_vector(19 downto 0) := (others => '0');
    signal dpath_jtype  : std_logic_vector(20 downto 0) := (others => '0');
    signal dpath_done  : std_logic := '0';
    signal dpath_jtaken: std_logic := '0';
    signal dpath_btaken: std_logic := '0';
    signal dpath_nxtpc : std_logic_vector(31 downto 0) := (others => '0');

    signal opA        : std_logic_vector(31 downto 0);
    signal opB        : std_logic_vector(31 downto 0);
    signal alu_result : std_logic_vector(31 downto 0);
    signal alu_valid  : std_logic;
    signal alu_done   : std_logic;

    signal bu_result  : std_logic_vector(31 downto 0);
    signal bu_valid   : std_logic;
    signal bu_done    : std_logic;
    signal bu_except  : std_logic;
    signal jtaken     : std_logic;

    signal mem_result : std_logic_vector(31 downto 0);
    signal mem_mwen   : std_logic_vector(3 downto 0);
    signal mem_ldone  : std_logic;
    signal mem_sdone  : std_logic;
    signal mem_done   : std_logic;
    signal mem_valid  : std_logic;
    signal mem_msaln  : std_logic;

    signal mul_result : std_logic_vector(31 downto 0);
    signal mul_done   : std_logic;
    signal mul_valid  : std_logic;

    signal lui_result : std_logic_vector(31 downto 0);
    signal lui_valid  : std_logic;
    signal lui_done   : std_logic;

    signal aui_result : std_logic_vector(31 downto 0);
    signal aui_valid  : std_logic;
    signal aui_done   : std_logic;

    signal result     : std_logic_vector(31 downto 0);
    signal valid      : std_logic;
    signal done       : std_logic;
begin
    
    CreateClock(clk=>i_clk, period=>5 ns);

    eDut : ControlEngine
    port map (
        -- System level signals
        i_clk    => i_clk,
        i_resetn => i_resetn,

        -- Bus Signals
        o_instr_addr   => instr_addr,
        o_instr_ren    => instr_ren,
        o_instr_wen    => instr_wen,
        o_instr_wdata  => instr_wdata,
        i_instr_rdata  => instr_rdata,
        i_instr_rvalid => instr_rvalid,

        -- Datapath Signals
        o_dpath_pc     => dpath_pc,
        o_dpath_opcode => dpath_opcode,
        o_dpath_rs1    => dpath_rs1,
        o_dpath_rs2    => dpath_rs2,
        o_dpath_rd     => dpath_rd,
        o_dpath_funct3 => dpath_funct3,
        o_dpath_funct7 => dpath_funct7,
        o_dpath_itype  => dpath_itype,
        o_dpath_stype  => dpath_stype,
        o_dpath_btype  => dpath_btype,
        o_dpath_utype  => dpath_utype,
        o_dpath_jtype  => dpath_jtype,
        i_dpath_done   => dpath_done,
        i_dpath_jtaken => dpath_jtaken,
        i_dpath_btaken => dpath_btaken,
        i_dpath_nxtpc  => dpath_nxtpc
    );

    eIMem : InstructionMemory
    port map (
        i_clk          => i_clk,
        i_resetn       => i_resetn,
        i_instr_addr   => instr_addr,
        i_instr_ren    => instr_ren,
        i_instr_wen    => instr_wen,
        i_instr_wdata  => instr_wdata,
        o_instr_rdata  => instr_rdata,
        o_instr_rvalid => instr_rvalid
    );


    eAlu : Alu
    port map (
        i_opcode => dpath_opcode,
        i_funct3 => dpath_funct3,
        i_funct7 => dpath_funct7,
        i_itype  => dpath_itype,
        i_opA    => opA,
        i_opB    => opB,
        i_shamt  => dpath_rs2,

        o_res    => alu_result,
        o_valid  => alu_valid
    );

    alu_done <= alu_valid;

    eBranchUnit : BranchUnit
    port map (
        i_pc     => dpath_pc,
        i_opcode => dpath_opcode,
        i_funct3 => dpath_funct3,
        i_itype  => dpath_itype,
        i_jtype  => dpath_jtype,
        i_btype  => dpath_btype,
        i_opA    => opA,
        i_opB    => opB,

        o_nxtpc   => dpath_nxtpc,
        o_pjpc    => bu_result,
        o_btaken  => dpath_btaken,
        o_jtaken  => jtaken,
        o_done    => bu_done,
        o_bexcept => bu_except
    );

    dpath_jtaken <= jtaken;
    bu_valid <= jtaken;

    eMemAccessUnit : MemAccessUnit
    port map (
        i_clk    => i_clk,
        i_opcode => dpath_opcode,
        i_opA    => opA,
        i_itype  => dpath_itype,
        i_stype  => dpath_stype,
        i_funct3 => dpath_funct3,
        
        o_addr => data_addr,
        o_men  => data_ren,
        o_mwen => data_wen,
        i_ack  => '1', -- Revisit this. Bus currently doesn't use it.

        i_rvalid => data_rvalid,
        i_rdata  => data_rdata,
        
        o_data  => mem_result,
        o_ldone => mem_ldone,
        o_sdone => mem_sdone,
        o_msaln => mem_msaln
    );

    mem_valid  <= mem_ldone;
    mem_done   <= mem_ldone or mem_sdone;
    data_wdata <= opB;
    
    eMExtension : MExtensionUnit
    port map (
        i_clk    => i_clk,
        i_opcode => dpath_opcode,
        i_funct3 => dpath_funct3,
        i_funct7 => dpath_funct7,
        i_opA    => opA,
        i_opB    => opB,
        o_result => mul_result,
        o_done   => mul_done
    );

    mul_valid <= mul_done;

    lui_result <= dpath_utype& x"000";
    lui_valid <= bool2bit(dpath_opcode = cLoadUpperOpcode);
    lui_done  <= lui_valid;
    
    aui_result <= std_logic_vector(unsigned(dpath_pc)+ unsigned(lui_result));
    aui_valid <= bool2bit(dpath_opcode = cAuipcOpcode);
    aui_done  <= aui_valid;

    ResultMux: process(
        alu_result, alu_valid, 
        bu_result,  bu_valid, 
        mem_result, mem_valid, 
        mul_result, mul_valid,
        lui_result, lui_valid,
        aui_result, aui_valid)
    begin
        if (alu_valid = '1') then
            result <= alu_result;
        elsif (bu_valid = '1') then
            result <= bu_result;
        elsif (mem_valid = '1') then
            result <= mem_result;
        elsif (mul_valid = '1') then
            result <= mul_result;
        elsif (lui_valid = '1') then
            result <= lui_result;
        elsif (aui_valid = '1') then
            result <= aui_result;
        else
            result <= x"00000000";
        end if;
    end process ResultMux;

    valid <= alu_valid or bu_valid or mem_valid or mul_valid or lui_valid or aui_valid;
    done  <= alu_done or bu_done or mem_done or mul_done or lui_done or aui_done;

    dpath_done <= done;

    eRegisters : RegisterFile
    generic map (
        cDataWidth    => 32,
        cAddressWidth => 5
    ) port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,
        i_rs1    => dpath_rs1,
        i_rs2    => dpath_rs2,
        i_rd     => dpath_rd,
        i_result => result,
        i_wen    => valid,
        o_opA    => opA,
        o_opB    => opB
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            -- Need to add verification to the address reading.
            if run("t_whitebox") then
                --check(false);
                i_resetn <= '0';
                wait until rising_edge(i_clk);
                wait for 100 ps;
                i_resetn <= '1';
                wait for 100 ns;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;