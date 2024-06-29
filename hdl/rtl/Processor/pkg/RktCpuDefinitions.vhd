library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

package RktCpuDefinitions is

    constant cFetchIdx     : natural := 0;
    constant cDecodeIdx    : natural := 1;
    constant cExecuteIdx   : natural := 2;
    constant cMemAccessIdx : natural := 3;
    constant cWritebackIdx : natural := 4;

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
        en    : std_logic;
        stype : std_logic;
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
        rd     : std_logic_vector(4 downto 0);
        funct3 : std_logic_vector(2 downto 0);
        itype  : std_logic_vector(11 downto 0);
    end record zicsr_controls_t;
    
end package RktCpuDefinitions;