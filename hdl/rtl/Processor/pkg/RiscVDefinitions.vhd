library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

package RiscVDefinitions is
    
    function get_opcode(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_rd(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_rs1(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_rs2(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_funct3(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_funct7(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_itype(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_stype(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_utype(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_btype(instr : std_logic_vector(31 downto 0)) return std_logic_vector;
    function get_jtype(instr : std_logic_vector(31 downto 0)) return std_logic_vector;

    constant cBranchOpcode    : std_logic_vector(6 downto 0) := "1100011";
    constant cLoadOpcode      : std_logic_vector(6 downto 0) := "0000011";
    constant cStoreOpcode     : std_logic_vector(6 downto 0) := "0100011";
    constant cAluOpcode       : std_logic_vector(6 downto 0) := "0110011";
    constant cAluImmedOpcode  : std_logic_vector(6 downto 0) := "0010011";
    constant cJumpOpcode      : std_logic_vector(6 downto 0) := "1101111";
    constant cJumpRegOpcode   : std_logic_vector(6 downto 0) := "1100111";
    constant cLoadUpperOpcode : std_logic_vector(6 downto 0) := "0110111";
    constant cAuipcOpcode     : std_logic_vector(6 downto 0) := "0010111";
    constant cFenceOpcode     : std_logic_vector(6 downto 0) := "0001111";
    constant cEcallOpcode     : std_logic_vector(6 downto 0) := "1110011";
    constant cMulDivOpcode    : std_logic_vector(6 downto 0) := "0110011";

    constant cMulFunct3    : std_logic_vector(2 downto 0) := "000";
    constant cMulhFunct3   : std_logic_vector(2 downto 0) := "001";
    constant cMulhsuFunct3 : std_logic_vector(2 downto 0) := "010";
    constant cMulhuFunct3  : std_logic_vector(2 downto 0) := "011";
    constant cDivFunct3    : std_logic_vector(2 downto 0) := "100";
    constant cDivuFunct3   : std_logic_vector(2 downto 0) := "101";
    constant cRemFunct3    : std_logic_vector(2 downto 0) := "110";
    constant cRemuFunct3   : std_logic_vector(2 downto 0) := "111";
    
end package RiscVDefinitions;

package body RiscVDefinitions is
    
    function get_opcode(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return instr(6 downto 0);
    end function;

    function get_rd(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return instr(11 downto 7);
    end function;

    function get_rs1(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable temp : std_logic_vector(4 downto 0);
    begin
        temp := instr(19 downto 15);
        return temp;
    end function;

    function get_rs2(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable temp : std_logic_vector(4 downto 0);
    begin
        temp := instr(24 downto 20);
        return temp;
    end function;

    function get_funct3(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable temp : std_logic_vector(2 downto 0);
    begin
        temp := instr(14 downto 12);
        return temp;
    end function;

    function get_funct7(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable temp : std_logic_vector(6 downto 0);
    begin
        temp := instr(31 downto 25); 
        return temp;
    end function;

    function get_itype(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return instr(31 downto 20);
    end function;

    function get_stype(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return get_funct7(instr) & get_rd(instr);
    end function;

    function get_utype(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return get_funct7(instr) & get_rs2(instr) & get_rs1(instr) & get_funct3(instr);
    end function;

    function get_btype(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0';
    end function;

    function get_jtype(instr : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & '0';
    end function;

end package body RiscVDefinitions;