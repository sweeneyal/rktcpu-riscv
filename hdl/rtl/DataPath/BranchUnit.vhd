library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;
    use universal.CommonTypesPkg.all;

entity BranchUnit is
    port (
        i_pc     : in std_logic_vector(31 downto 0);
        i_opcode : in std_logic_vector(6 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        i_rd     : in std_logic_vector(4 downto 0);
        i_rs1    : in std_logic_vector(4 downto 0);
        i_itype  : in std_logic_vector(11 downto 0);
        i_jtype  : in std_logic_vector(20 downto 0);
        i_btype  : in std_logic_vector(12 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);

        o_nxtpc  : out std_logic_vector(31 downto 0);
        o_pjpc   : out std_logic_vector(31 downto 0);
        o_btaken : out std_logic;
        o_jtaken : out std_logic
    );
end entity BranchUnit;

architecture rtl of BranchUnit is
begin
    
    BranchAddress: process(i_pc, i_btype, i_jtype, i_opA, i_itype)
    begin
        if (i_opcode = cBranchOpcode) then
            o_nxtpc <= std_logic_vector(s32_t(i_pc) + to_s32(i_btype));
        elsif (i_opcode = cJumpOpcode) then
            o_nxtpc <= std_logic_vector(s32_t(i_pc) + 
                to_s32(i_jtype));
        elsif (i_opcode = cJumpRegOpcode) then
            o_nxtpc <= std_logic_vector(s32_t(i_opA) + to_s32(i_itype));
        else
            o_nxtpc <= std_logic_vector(s32_t(i_pc) + 4);
        end if;
        o_pjpc <= std_logic_vector(s32_t(i_pc) + 4);
    end process BranchAddress;

    SetBranchEnable: process(i_funct3, i_opcode, i_opA, i_opB)
    begin
        if (i_opcode = cJumpOpcode) then
            o_jtaken <= '1'; -- Enable automatically set for Jumps
            o_btaken <= '0';
        elsif (i_opcode = cJumpRegOpcode) then
            o_jtaken <= '1';
            o_btaken <= '0';
        elsif (i_opcode = cBranchOpcode) then
            o_jtaken <= '0';
            case i_funct3 is
                when "000" =>
                    if (i_opA = i_opB) then
                        o_btaken <= '1';
                    else
                        o_btaken <= '0';
                    end if;
                when "001" =>
                    if (i_opA /= i_opB) then
                        o_btaken <= '1';
                    else
                        o_btaken <= '0';
                    end if;
                when "100" =>
                    if (s32_t(i_opA) < s32_t(i_opB)) then
                        o_btaken <= '1';
                    else
                        o_btaken <= '0';
                    end if;
                when "101" =>
                    if (s32_t(i_opA) >= s32_t(i_opB)) then
                        o_btaken <= '1';
                    else
                        o_btaken <= '0';
                    end if;
                when "110" =>
                    if (u32_t(i_opA) < u32_t(i_opB)) then
                        o_btaken <= '1';
                    else
                        o_btaken <= '0';
                    end if;
                when "111" =>
                    if (u32_t(i_opA) >= u32_t(i_opB)) then
                        o_btaken <= '1';
                    else
                        o_btaken <= '0';
                    end if;
                when others =>
                    o_btaken <= '0';
            
            end case;
        else
            o_jtaken <= '0';
            o_btaken <= '0';
        end if;
    end process SetBranchEnable;
    
end architecture rtl;