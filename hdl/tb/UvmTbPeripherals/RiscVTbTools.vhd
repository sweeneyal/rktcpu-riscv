library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;
    use osvvm.RandomPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.RiscVDefinitions.all;

package RiscVTbTools is

    type register_tb_t is record
        valid : boolean;
        value : std_logic_vector(31 downto 0);
    end record register_tb_t;
    type register_map_t is array (0 to 31) of register_tb_t;

    function generate_registers(default_value : std_logic_vector(31 downto 0)) return register_map_t;

    impure function generate_instruction(
        registers : register_map_t; 
        forcedOpcode : integer := -1) 
    return std_logic_vector;

    function get_opcode_index(opcode : std_logic_vector(6 downto 0)) return integer;
    
end package RiscVTbTools;

package body RiscVTbTools is

    function generate_registers(default_value : std_logic_vector(31 downto 0)) return register_map_t is
        variable registers : register_map_t;
    begin
        for ii in 0 to 31 loop
            if ii = 0 then
                registers(ii).value := x"00000000";
            else
                registers(ii).value := default_value;
            end if;
            registers(ii).valid := true;
        end loop;
        return registers;
    end function;
    
    impure function generate_instruction(
        registers : register_map_t; 
        forcedOpcode : integer := -1) 
    return std_logic_vector is
        variable RandData : RandomPType;
        variable valid_instruction : boolean := false;
        variable opcode_idx : natural;
        variable opcode : std_logic_vector(6 downto 0);
        variable funct3 : natural;
        variable funct7 : std_logic_vector(6 downto 0);
        variable rs1    : integer := -1;
        variable rs2    : integer := -1;
        variable rd     : integer := -1;
        variable itype  : std_logic_vector(11 downto 0);
        variable stype  : std_logic_vector(11 downto 0);
        variable btype  : std_logic_vector(12 downto 0);
        variable jtype  : std_logic_vector(20 downto 0);
        variable utype  : std_logic_vector(31 downto 0);
        variable instruction : std_logic_vector(31 downto 0);
    begin
        while not valid_instruction loop
            -- Each possible opcode index has a valid opcode associated with it.
            -- Each opcode then has a set of all possible valid instructions for these.
            -- Generate an instruction that could legally occur without incurring a 
            -- fault of some kind or using uninitialized (invalid) registers.
            if forcedOpcode /= -1 then
                opcode_idx := forcedOpcode;
            else
                opcode_idx := RandData.RandInt(0, 10);
            end if;
            case opcode_idx is
                when 0 =>
                    instruction(6 downto 0) := cBranchOpcode;
                    -- Pick a funct3 from 000, 001, 100, 101, 110, 111
                    funct3 := RandData.RandInt(0, 7);
                    while funct3 = 2 or funct3 = 3 loop
                        -- Reroll if we get a bad funct3
                        funct3 := RandData.RandInt(0, 7);
                    end loop;
                    instruction(14 downto 12) := to_slv(funct3, 3);

                    -- Pick two registers to compare
                    while rs1 < 0 loop
                        rs1 := RandData.RandInt(0, 31);
                        if (not registers(rs1).valid) then -- Fix this
                            rs1 := -1; -- Reroll if we get a bad register
                        end if;
                    end loop;
                    instruction(19 downto 15) := to_slv(rs1, 5);
                    while rs2 < 0 loop
                        rs2 := RandData.RandInt(0, 31);
                        if (not registers(rs2).valid) then
                            rs2 := -1; -- Reroll if we get a bad register
                        end if;
                    end loop;
                    instruction(24 downto 20) := to_slv(rs2, 5);

                    -- Pick a random immediate for the PC
                    btype := RandData.RandSlv("0000000000000", "1111111111111");
                    instruction(31) := btype(12);
                    instruction(30 downto 25) := btype(10 downto 5);
                    instruction(11 downto 7) := btype(4 downto 1) & btype(11);

                    -- Indicate that this is a valid instruction.
                    valid_instruction := true;

                when 1 =>
                    instruction(6 downto 0) := cLoadOpcode;
                    -- Pick a random immediate for the PC
                    itype := RandData.RandSlv("000000000000", "111111111111");
                    instruction(31 downto 20) := itype;

                    -- Pick a funct from 000, 001, 010, 100, 101
                    funct3 := RandData.RandInt(0, 5);
                    while funct3 = 3 loop
                        funct3 := RandData.RandInt(0, 5); -- Reroll for valid funct3
                    end loop;
                    instruction(14 downto 12) := to_slv(funct3, 3);

                    -- Pick a register to build the load address with
                    while rs1 < 0 loop
                        rs1 := RandData.RandInt(0, 31);
                        if (not registers(rs1).valid) then -- Fix this
                            rs1 := -1;
                        end if;
                    end loop;
                    instruction(19 downto 15) := to_slv(rs1, 5);

                    -- Pick a destination register.
                    -- We don't need to reroll because this makes instructions valid.
                    rd := RandData.RandInt(1, 31);
                    instruction(11 downto 7) := to_slv(rd, 5);
                    valid_instruction := true;

                when 2 =>
                    instruction(6 downto 0) := cStoreOpcode;
                    -- Pick a funct from 000, 001, 010
                    funct3 := RandData.RandInt(0, 2);
                    instruction(14 downto 12) := to_slv(funct3, 3);
                    -- Pick two registers to compare
                    while rs1 < 0 loop
                        rs1 := RandData.RandInt(0, 31);
                        if (not registers(rs1).valid) then
                            rs1 := -1;
                        end if;
                    end loop;
                    instruction(19 downto 15) := to_slv(rs1, 5);
                    while rs2 < 0 loop
                        rs2 := RandData.RandInt(0, 31);
                        if (not registers(rs2).valid) then
                            rs2 := -1;
                        end if;
                    end loop;
                    instruction(24 downto 20) := to_slv(rs2, 5);
                    -- Generate a stype immediate
                    stype := RandData.RandSlv("000000000000", "111111111111");
                    instruction(31 downto 25) := stype(11 downto 5);
                    instruction(11 downto 7) := stype(4 downto 0);
                    valid_instruction := true;
            
                when 3 =>
                    -- The muldiv opcode and ALU opcodes are the same.
                    if (RandData.RandInt(0,7) = 0) then
                        instruction(6 downto 0) := cMulDivOpcode;
                        -- Pick a funct from 000, 001, 010, 100, 101
                        funct3 := RandData.RandInt(0, 7);
                        instruction(14 downto 12) := to_slv(funct3, 3);
                        -- Pick source registers
                        while rs1 < 0 loop
                            rs1 := RandData.RandInt(0, 31);
                            if (not registers(rs1).valid) then -- Fix this
                                rs1 := -1;
                            end if;
                        end loop;
                        instruction(19 downto 15) := to_slv(rs1, 5);
                        while rs2 < 0 loop
                            rs2 := RandData.RandInt(0, 31);
                            if (not registers(rs2).valid or registers(rs2).value = x"00000000") then
                                rs2 := -1;
                            end if;
                        end loop;
                        instruction(24 downto 20) := to_slv(rs2, 5);
                        -- Pick a destination register.
                        rd := RandData.RandInt(1, 31);
                        instruction(11 downto 7) := to_slv(rd, 5);
                        -- Funct7 is the same for all.
                        funct7 := "0000001";
                        instruction(31 downto 25) := funct7;
                        valid_instruction := true;
                    else
                        instruction(6 downto 0) := cAluOpcode;
                        -- Pick a funct from 0 to 7
                        funct3 := RandData.RandInt(0, 7);
                        instruction(14 downto 12) := to_slv(funct3, 3);
                        -- Based off funct3, randomly choose a funct7 if there are multiple options.
                        if (funct3 = 0 or funct3 = 5) and (RandData.RandInt(0, 1) = 1) then
                            funct7 := "0100000";
                        else
                            funct7 := "0000000";
                        end if;
                        instruction(31 downto 25) := funct7;
                        -- Pick two registers to operate on
                        while rs1 < 0 loop
                            rs1 := RandData.RandInt(0, 31);
                            if (not registers(rs1).valid) then -- Fix this
                                rs1 := -1;
                            end if;
                        end loop;
                        instruction(19 downto 15) := to_slv(rs1, 5);
                        while rs2 < 0 loop
                            rs2 := RandData.RandInt(0, 31);
                            if (not registers(rs2).valid) then -- Fix this
                                rs2 := -1;
                            end if;
                        end loop;
                        instruction(24 downto 20) := to_slv(rs2, 5);
                        -- Pick a destination address.
                        while rd < 1 loop
                            rd := RandData.RandInt(1, 31);
                            if (not registers(rd).valid) then -- Fix this
                                rd := -1;
                            end if;
                        end loop;
                        instruction(11 downto 7) := to_slv(rd, 5);
                        valid_instruction := true;
                    end if;

                when 4 =>
                    instruction(6 downto 0) := cAluImmedOpcode;
                    -- Pick a funct from 0 to 7
                    funct3 := RandData.RandInt(0, 7);
                    instruction(14 downto 12) := to_slv(funct3, 3);
                    -- Based off funct3, identify if this instruction is an itype or a shamt
                    case funct3 is
                        when 0 | 2 | 3 | 4 | 6 | 7 =>
                            -- Pick a random immediate for the PC
                            itype := RandData.RandSlv("000000000000", "111111111111");
                            instruction(31 downto 20) := itype;
                    
                        when 1 | 5 =>
                            -- Pick funct7 based on funct3 and for funct3 = 5, randomly pick funct7
                            if funct3 = 1 or (RandData.RandInt(0, 1) = 1) then
                                funct7 := "0000000";
                            else
                                funct7 := "0100000";
                            end if;
                            instruction(31 downto 25) := funct7;
                            rs2 := RandData.RandInt(0, 7);
                            instruction(24 downto 20) := to_slv(rs2, 5);
                        when others =>
                            assert false report "Not supposed to happen" severity error;

                    end case;
                    -- Pick a register to operate on
                    while rs1 < 0 loop
                        rs1 := RandData.RandInt(0, 31);
                        if (not registers(rs1).valid) then -- Fix this
                            rs1 := -1;
                        end if;
                    end loop;
                    instruction(19 downto 15) := to_slv(rs1, 5);
                    -- Pick a destination address.
                    while rd < 1 loop
                        rd := RandData.RandInt(1, 31);
                        if (not registers(rd).valid) then -- Fix this
                            rd := -1;
                        end if;
                    end loop;
                    instruction(11 downto 7) := to_slv(rd, 5);
                    valid_instruction := true;

                when 5 =>
                    instruction(6 downto 0) := cJumpOpcode;
                    -- Generate a random jtype immediate
                    jtype := RandData.RandSlv("000000000000000000000", 
                        "1111111111111111111111");
                    instruction(31) := jtype(20);
                    instruction(30 downto 21) := jtype(10 downto 1);
                    instruction(20) := jtype(11);
                    instruction(19 downto 12) := jtype(19 downto 12);
                    -- Pick a destination register.
                    rd := RandData.RandInt(0, 31);
                    instruction(11 downto 7) := to_slv(rd, 5);
                    valid_instruction := true;

                when 6 =>
                    instruction(6 downto 0) := cJumpRegOpcode;
                    funct3 := 0;
                    instruction(14 downto 12) := to_slv(funct3, 3);
                    -- Pick two registers to operate on
                    while rs1 < 0 loop
                        rs1 := RandData.RandInt(0, 31);
                        if (not registers(rs1).valid) then -- Fix this
                            rs1 := -1;
                        end if;
                    end loop;
                    instruction(19 downto 15) := to_slv(rs1, 5);
                    -- Pick a destination register.
                    rd := RandData.RandInt(0, 31);
                    instruction(11 downto 7) := to_slv(rd, 5);
                    -- Pick a random immediate for the PC
                    itype := RandData.RandSlv("000000000000", "111111111111");
                    instruction(31 downto 20) := itype;
                    valid_instruction := true;

                when 7 =>
                    instruction(6 downto 0) := cLoadUpperOpcode;
                    -- Generate a random jtype immediate
                    utype := RandData.RandSlv(x"00000000", x"FFFFFFFF");
                    instruction(31 downto 12) := utype(31 downto 12);
                    -- Pick a destination register.
                    rd := RandData.RandInt(1, 31);
                    instruction(11 downto 7) := to_slv(rd, 5);
                    valid_instruction := true;

                when 8 =>
                    instruction(6 downto 0) := cAuipcOpcode;
                    -- Generate a random jtype immediate
                    utype := RandData.RandSlv(x"00000000", x"FFFFFFFF");
                    instruction(31 downto 12) := utype(31 downto 12);
                    -- Pick a destination register.
                    rd := RandData.RandInt(1, 31);
                    instruction(11 downto 7) := to_slv(rd, 5);
                    valid_instruction := true;
            
                when 9 =>
                    instruction(6 downto 0) := cFenceOpcode;
                    valid_instruction := false; -- Not implementing fence opcodes currently

                when 10 =>
                    instruction(6 downto 0) := cEcallOpcode;
                    if (RandData.RandInt(0, 1) = 1) then
                        instruction(31 downto 7) := (others => '0');
                        valid_instruction := false; -- Not implementing standard ECALLS currently.
                    else
                        -- Pick a funct from 000, 001, 010, 100, 101
                        funct3 := RandData.RandInt(1, 7);
                        while funct3 = 4 loop
                            funct3 := RandData.RandInt(4, 7); -- Reroll for valid funct3
                        end loop;
                        instruction(14 downto 12) := to_slv(funct3, 3);
                        -- Pick a source register
                        while rs1 < 0 loop
                            rs1 := RandData.RandInt(0, 31);
                            if (not registers(rs1).valid) then -- Fix this
                                rs1 := -1;
                            end if;
                        end loop;
                        instruction(19 downto 15) := to_slv(rs1, 5);
                        -- Pick a destination register.
                        rd := RandData.RandInt(1, 31);
                        instruction(11 downto 7) := to_slv(rd, 5);
                        -- CSR instructions are notionally implemented but
                        -- not sure how to generate instructions for it without coming up with a list of
                        -- valid addresses.
                        valid_instruction := false; 
                    end if;

                when others =>
                    report "Invalid instruction.";
                    valid_instruction := false;

            end case;

            if (forcedOpcode /= -1 and valid_instruction = false) then
                assert false;
            end if;
        end loop;

        return instruction;
    end function;

    function get_opcode_index(opcode : std_logic_vector(6 downto 0)) return integer is
    begin
        case opcode is
            when cBranchOpcode =>
                return 0;
            when cLoadOpcode =>
                return 1;
            when cStoreOpcode =>
                return 2;
            when cAluOpcode => -- Also handles MULDIV
                return 3;
            when cAluImmedOpcode =>
                return 4;
            when cJumpOpcode =>
                return 5;
            when cJumpRegOpcode =>
                return 6;
            when cLoadUpperOpcode =>
                return 7;
            when cAuipcOpcode =>
                return 8;
            when cFenceOpcode =>
                return 9;
            when cEcallOpcode =>
                return 10;
            when others =>
                return -1;
        end case;
    end function;
    
end package body RiscVTbTools;