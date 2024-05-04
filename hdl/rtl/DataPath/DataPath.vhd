library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.DataPathEntities.all;
    use scrv.RiscVDefinitions.all;

entity DataPath is
    port (
        -- System level signals
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- Bus Signals
        o_data_addr   : out std_logic_vector(31 downto 0);
        o_data_ren    : out std_logic;
        o_data_wen    : out std_logic_vector(3 downto 0);
        o_data_wdata  : out std_logic_vector(31 downto 0);
        i_data_rdata  : in std_logic_vector(31 downto 0);
        i_data_rvalid : in std_logic;

        -- Datapath Signals
        i_dpath_pc     : in std_logic_vector(31 downto 0);
        i_dpath_opcode : in std_logic_vector(6 downto 0);
        i_dpath_rs1    : in std_logic_vector(4 downto 0);
        i_dpath_rs2    : in std_logic_vector(4 downto 0);
        i_dpath_rd     : in std_logic_vector(4 downto 0);
        i_dpath_funct3 : in std_logic_vector(2 downto 0);
        i_dpath_funct7 : in std_logic_vector(6 downto 0);
        i_dpath_itype  : in std_logic_vector(11 downto 0);
        i_dpath_stype  : in std_logic_vector(11 downto 0);
        i_dpath_btype  : in std_logic_vector(12 downto 0);
        i_dpath_utype  : in std_logic_vector(19 downto 0);
        i_dpath_jtype  : in std_logic_vector(20 downto 0);
        o_dpath_done   : out std_logic;
        o_dpath_jtaken : out std_logic;
        o_dpath_btaken : out std_logic;
        o_dpath_nxtpc  : out std_logic_vector(31 downto 0);

        -- Debug verification signals
        o_dbg_result : out std_logic_vector(31 downto 0);
        o_dbg_valid  : out std_logic
    );
end entity DataPath;

architecture rtl of DataPath is
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

    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of eAlu : label is "true";
    attribute DONT_TOUCH of eBranchUnit : label is "true";
    attribute DONT_TOUCH of eMemAccessUnit : label is "true";
    attribute DONT_TOUCH of ResultMux : label is "true";
begin
    
    eAlu : Alu
    port map (
        i_opcode => i_dpath_opcode,
        i_funct3 => i_dpath_funct3,
        i_funct7 => i_dpath_funct7,
        i_itype  => i_dpath_itype,
        i_opA    => opA,
        i_opB    => opB,
        i_shamt  => i_dpath_rs2,

        o_res    => alu_result,
        o_valid  => alu_valid
    );

    alu_done <= alu_valid;

    eBranchUnit : BranchUnit
    port map (
        i_pc     => i_dpath_pc,
        i_opcode => i_dpath_opcode,
        i_funct3 => i_dpath_funct3,
        i_itype  => i_dpath_itype,
        i_jtype  => i_dpath_jtype,
        i_btype  => i_dpath_btype,
        i_opA    => opA,
        i_opB    => opB,

        o_nxtpc   => o_dpath_nxtpc,
        o_pjpc    => bu_result,
        o_btaken  => o_dpath_btaken,
        o_jtaken  => jtaken,
        o_done    => bu_done,
        o_bexcept => bu_except
    );

    o_dpath_jtaken <= jtaken;
    bu_valid <= jtaken;

    eMemAccessUnit : MemAccessUnit
    port map (
        i_clk    => i_clk,
        i_opcode => i_dpath_opcode,
        i_opA    => opA,
        i_itype  => i_dpath_itype,
        i_stype  => i_dpath_stype,
        i_funct3 => i_dpath_funct3,
        
        o_addr => o_data_addr,
        o_men  => o_data_ren,
        o_mwen => o_data_wen,
        i_rvalid => i_data_rvalid,
        i_rdata  => i_data_rdata,
        
        o_data  => mem_result,
        o_ldone => mem_ldone,
        o_sdone => mem_sdone,
        o_msaln => mem_msaln
    );

    mem_valid    <= mem_ldone;
    mem_done     <= mem_ldone or mem_sdone;
    o_data_wdata <= opB;
    
    eMExtension : MExtensionUnit
    port map (
        i_clk    => i_clk,
        i_opcode => i_dpath_opcode,
        i_funct3 => i_dpath_funct3,
        i_funct7 => i_dpath_funct7,
        i_opA    => opA,
        i_opB    => opB,
        o_result => mul_result,
        o_done   => mul_done
    );

    mul_valid <= mul_done;

    lui_result <= i_dpath_utype & x"000";
    lui_valid <= bool2bit(i_dpath_opcode = cLoadUpperOpcode);
    lui_done  <= lui_valid;
    
    aui_result <= std_logic_vector(unsigned(i_dpath_pc) + unsigned(lui_result));
    aui_valid <= bool2bit(i_dpath_opcode = cAuipcOpcode);
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

    o_dpath_done <= done;

    eRegisters : RegisterFile
    generic map (
        cDataWidth    => 32,
        cAddressWidth => 5
    ) port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,
        i_rs1    => i_dpath_rs1,
        i_rs2    => i_dpath_rs2,
        i_rd     => i_dpath_rd,
        i_result => result,
        i_wen    => valid,
        o_opA    => opA,
        o_opB    => opB
    );

end architecture rtl;