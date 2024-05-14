library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library rktcpu;
    use rktcpu.RiscVDefinitions.all;

entity Alu is
    port (
        i_opcode : in std_logic_vector(6 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        i_funct7 : in std_logic_vector(6 downto 0);
        i_itype  : in std_logic_vector(11 downto 0);
        i_opA    : in std_logic_vector(31 downto 0);
        i_opB    : in std_logic_vector(31 downto 0);
        i_shamt  : in std_logic_vector(4 downto 0);

        o_res    : out std_logic_vector(31 downto 0);
        o_valid  : out std_logic
    );
end entity Alu;

architecture rtl of Alu is
begin

    -- This will need to meet timing to work. It essentially expects to be done doing all operations here
    -- in under a clock cycle.
    AluOperations: process(i_opcode, i_funct3, i_funct7, i_itype, i_opA, i_opB, i_shamt)
    begin
        case i_funct3 is
            when "000" =>
                if (i_opcode = cAluImmedOpcode) then -- ADDI
                    o_res <= std_logic_vector(s32_t(i_opA) + to_s32(i_itype));
                else
                    if (i_funct7 = "0100000") then -- SUB
                        o_res <= std_logic_vector(s32_t(i_opA) - to_s32(i_opB));
                    else -- ADD
                        o_res <= std_logic_vector(s32_t(i_opA) + to_s32(i_opB));
                    end if;
                end if;
            when "001" => -- SLLI
                if (i_opcode = cAluImmedOpcode) then
                    o_res <= std_logic_vector(u32_t(i_opA) sll to_natural(i_shamt));
                else -- SLL
                    o_res <= std_logic_vector(u32_t(i_opA) sll to_natural(i_opB));
                end if;
            when "010" =>
                if (i_opcode = cAluImmedOpcode) then -- SLTI
                    o_res <= (31 downto 1 => '0') & Bool2Bit(s32_t(i_opA) < to_s32(i_itype));
                else -- SLT
                    o_res <= (31 downto 1 => '0') & Bool2Bit(s32_t(i_opA) < s32_t(i_opB));
                end if;
            when "011" =>
                if (i_opcode = cAluImmedOpcode) then -- SLTUI
                    o_res <= (31 downto 1 => '0') & Bool2Bit(u32_t(i_opA) < to_u32(i_itype));
                else -- SLTU
                    o_res <= (31 downto 1 => '0') & Bool2Bit(u32_t(i_opA) < u32_t(i_opB));
                end if;
            when "100" =>
                if (i_opcode = cAluImmedOpcode) then -- XORI
                    o_res <= i_opA xor std_logic_vector(to_s32(i_itype));
                else -- XOR
                    o_res <= i_opA xor i_opB;
                end if;
            when "101" =>
                if (i_opcode = cAluImmedOpcode) then
                    if (i_funct7 = "0100000") then -- SRAI
                        o_res <= std_logic_vector(shift_right(signed(i_opA), to_natural(i_shamt)));
                    else -- SRLI
                        o_res <= std_logic_vector(signed(i_opA) srl to_natural(i_shamt));
                    end if;
                else
                    if (i_funct7 = "0100000") then -- SRA
                        o_res <= std_logic_vector(shift_right(signed(i_opA), to_natural(i_opB)));
                    else -- SRL
                        o_res <= std_logic_vector(unsigned(i_opA) srl to_natural(i_opB));
                    end if;
                end if;
            when "110" =>
                if (i_opcode = cAluImmedOpcode) then -- ORI
                    o_res <= i_opA or std_logic_vector(to_s32(i_itype));
                else -- OR
                    o_res <= i_opA or i_opB;
                end if;
            when "111" =>
                if (i_opcode = cAluImmedOpcode) then -- ANDI
                    o_res <= i_opA and std_logic_vector(to_s32(i_itype));
                else -- AND
                    o_res <= i_opA and i_opB;
                end if;
            when others =>
                o_res <= (others => '0');
        end case;
    end process AluOperations;

    SetAluEnable: process(i_opcode, i_funct7)
    begin
        o_valid <= Bool2Bit((i_opcode = cAluImmedOpcode) or (i_opcode = cAluOpcode and (i_funct7 = "0100000" or i_funct7 = "0000000")));
    end process SetAluEnable;
    
end architecture rtl;