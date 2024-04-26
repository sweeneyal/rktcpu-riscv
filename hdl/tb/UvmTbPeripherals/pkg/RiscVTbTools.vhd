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

    procedure simulate_instruction(
        variable registers : inout register_map_t;

        -- Bus Signals
        signal o_data_addr   : out std_logic_vector(31 downto 0);
        signal o_data_ren    : out std_logic;
        signal o_data_wen    : out std_logic_vector(3 downto 0);
        signal o_data_wdata  : out std_logic_vector(31 downto 0);
        signal i_data_rdata  : in std_logic_vector(31 downto 0);
        signal i_data_rvalid : in std_logic;

        -- Datapath Signals
        signal i_dpath_pc     : in std_logic_vector(31 downto 0);
        signal i_dpath_opcode : in std_logic_vector(6 downto 0);
        signal i_dpath_rs1    : in std_logic_vector(4 downto 0);
        signal i_dpath_rs2    : in std_logic_vector(4 downto 0);
        signal i_dpath_rd     : in std_logic_vector(4 downto 0);
        signal i_dpath_funct3 : in std_logic_vector(2 downto 0);
        signal i_dpath_funct7 : in std_logic_vector(6 downto 0);
        signal i_dpath_itype  : in std_logic_vector(11 downto 0);
        signal i_dpath_stype  : in std_logic_vector(11 downto 0);
        signal i_dpath_btype  : in std_logic_vector(12 downto 0);
        signal i_dpath_utype  : in std_logic_vector(19 downto 0);
        signal i_dpath_jtype  : in std_logic_vector(20 downto 0);
        signal o_dpath_done   : out std_logic;
        signal o_dpath_jtaken : out std_logic;
        signal o_dpath_btaken : out std_logic;
        signal o_dpath_nxtpc  : out std_logic_vector(31 downto 0)
    );
    
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

    procedure simulate_instruction(
        variable registers : inout register_map_t;

        -- Bus Signals
        signal o_data_addr   : out std_logic_vector(31 downto 0);
        signal o_data_ren    : out std_logic;
        signal o_data_wen    : out std_logic_vector(3 downto 0);
        signal o_data_wdata  : out std_logic_vector(31 downto 0);
        signal i_data_rdata  : in std_logic_vector(31 downto 0);
        signal i_data_rvalid : in std_logic;

        -- Datapath Signals
        signal i_dpath_pc     : in std_logic_vector(31 downto 0);
        signal i_dpath_opcode : in std_logic_vector(6 downto 0);
        signal i_dpath_rs1    : in std_logic_vector(4 downto 0);
        signal i_dpath_rs2    : in std_logic_vector(4 downto 0);
        signal i_dpath_rd     : in std_logic_vector(4 downto 0);
        signal i_dpath_funct3 : in std_logic_vector(2 downto 0);
        signal i_dpath_funct7 : in std_logic_vector(6 downto 0);
        signal i_dpath_itype  : in std_logic_vector(11 downto 0);
        signal i_dpath_stype  : in std_logic_vector(11 downto 0);
        signal i_dpath_btype  : in std_logic_vector(12 downto 0);
        signal i_dpath_utype  : in std_logic_vector(19 downto 0);
        signal i_dpath_jtype  : in std_logic_vector(20 downto 0);
        signal o_dpath_done   : out std_logic;
        signal o_dpath_jtaken : out std_logic;
        signal o_dpath_btaken : out std_logic;
        signal o_dpath_nxtpc  : out std_logic_vector(31 downto 0)
    ) is
        variable lui_result : std_logic_vector(31 downto 0);
        variable opA        : std_logic_vector(31 downto 0);
        variable opB        : std_logic_vector(31 downto 0);
        variable rrem       : std_logic_vector(31 downto 0);
        variable div        : std_logic_vector(31 downto 0);
    begin
        o_data_addr    <= x"00000000";
        o_data_ren     <= '0';
        o_data_wen     <= "0000";
        o_data_wdata   <= x"00000000";
        o_dpath_done   <= '0';
        o_dpath_jtaken <= '0';
        o_dpath_btaken <= '0';
        o_dpath_nxtpc  <= x"00000000";

        opA := registers(to_natural(i_dpath_rs1)).value;
        opB := registers(to_natural(i_dpath_rs2)).value;
        case i_dpath_opcode is
            when cBranchOpcode =>
                -- Identify what type of branch this is
                case i_dpath_funct3 is
                    when "000" =>
                        -- beq
                        if opA = opB then
                            o_dpath_btaken <= '1';
                        end if;
                        o_dpath_nxtpc <= std_logic_vector(unsigned(i_dpath_pc) + 
                            unsigned(resize(signed(i_dpath_btype), 32)));
                        o_dpath_done   <= '1';
                    when "001" =>
                        -- bne
                        if opA /= opB then
                            o_dpath_btaken <= '1';
                        end if;
                        o_dpath_nxtpc <= std_logic_vector(unsigned(i_dpath_pc) + 
                            unsigned(resize(signed(i_dpath_btype), 32)));
                        o_dpath_done <= '1';
                    when "100" =>
                        -- blt
                        if signed(opA) < signed(opB) then
                            o_dpath_btaken <= '1';
                        end if;
                        o_dpath_nxtpc <= std_logic_vector(unsigned(i_dpath_pc) + 
                            unsigned(resize(signed(i_dpath_btype), 32)));
                        o_dpath_done <= '1';
                    when "101" =>
                        -- bge
                        if signed(opA) >= signed(opB) then
                            o_dpath_btaken <= '1';
                        end if;
                        o_dpath_nxtpc <= std_logic_vector(unsigned(i_dpath_pc) + 
                            unsigned(resize(signed(i_dpath_btype), 32)));
                        o_dpath_done <= '1';
                    when "110" =>
                        -- bltu
                        if unsigned(opA) < unsigned(opB) then
                            o_dpath_btaken <= '1';
                        end if;
                        o_dpath_nxtpc <= std_logic_vector(unsigned(i_dpath_pc) + 
                            unsigned(resize(signed(i_dpath_btype), 32)));
                        o_dpath_done <= '1';
                    when "111" =>
                        -- bgeu
                        if unsigned(opA) >= unsigned(opB) then
                            o_dpath_btaken <= '1';
                        end if;
                        o_dpath_nxtpc <= std_logic_vector(unsigned(i_dpath_pc) + 
                            unsigned(resize(signed(i_dpath_btype), 32)));
                        o_dpath_done <= '1';
                    when others =>
                        assert false report "Invalid funct3 during branch";
                end case;
            when cLoadOpcode =>
                null;
            when cStoreOpcode =>
                null;
            when cAluOpcode =>
                if (i_dpath_funct7 = "0000001") then -- MULDIV
                    case i_dpath_funct3 is
                        when "000" =>
                            -- MUL
                            registers(to_natural(i_dpath_rd)).value := shape(
                                std_logic_vector(signed(opA) * 
                                signed(opB)),
                                31, 0);
                        when "001" =>
                            -- MULH
                            registers(to_natural(i_dpath_rd)).value := shape(
                                std_logic_vector(signed(opA) * 
                                signed(opB)),
                                63, 32);
                        when "010" =>
                            -- MULHSU
                            registers(to_natural(i_dpath_rd)).value := shape(
                                std_logic_vector(resize(signed(opA), 64) * 
                                signed(resize(unsigned(opB), 64))),
                                63, 32);
                        when "011" =>
                            -- MULHU
                            registers(to_natural(i_dpath_rd)).value := shape(
                                std_logic_vector(unsigned(opA) * 
                                unsigned(opB)),
                                63, 32);
                        when "100" =>
                            -- DIV
                            div := std_logic_vector(divide(signed(opA), signed(opB)));
                            registers(to_natural(i_dpath_rd)).value := div;
                        when "101" =>
                            -- REM
                            div := std_logic_vector(divide(signed(opA), signed(opB)));
                            if opA(31) /= opB(31) then
                                if opA(31) = '1' then
                                    rrem := std_logic_vector(unsigned(opA) - shape(unsigned(-signed(div)) * unsigned(opB), 31, 0));
                                    rrem := std_logic_vector(unsigned(-signed(rrem)));
                                else
                                    rrem := std_logic_vector(unsigned(opA) - shape(unsigned(-signed(div)) * unsigned(opB), 31, 0));
                                end if;
                            else
                                rrem := std_logic_vector(unsigned(opA) - shape(unsigned(div) * unsigned(opB), 31, 0));
                            end if;
                            registers(to_natural(i_dpath_rd)).value := rrem;
                        when "110" =>
                            -- DIVU
                            div := std_logic_vector(divide(unsigned(opA), unsigned(opB)));
                            registers(to_natural(i_dpath_rd)).value := div;
                        when "111" =>
                            -- REMU
                            div  := std_logic_vector(divide(unsigned(opA), unsigned(opB)));
                            rrem := std_logic_vector(unsigned(opA) - shape(unsigned(div) * unsigned(opB), 31, 0));
                            registers(to_natural(i_dpath_rd)).value := rrem;
                        when others =>
                            assert false report "Invalid MULDIV funct3";
                    end case;
                else
                    case i_dpath_funct3 is
                        when "000" =>
                            if (i_dpath_funct7 = "0100000") then -- SUB
                                registers(to_natural(i_dpath_rd)).value := std_logic_vector(s32_t(opA) - to_s32(opB));
                            else -- ADD
                                registers(to_natural(i_dpath_rd)).value := std_logic_vector(s32_t(opA) + to_s32(opB));
                            end if;
                        when "001" => -- SLLI
                            registers(to_natural(i_dpath_rd)).value := std_logic_vector(u32_t(opA) sll to_natural(opB));
                        when "010" =>
                            registers(to_natural(i_dpath_rd)).value := (31 downto 1 => '0') & Bool2Bit(s32_t(opA) < s32_t(opB));
                        when "011" =>
                            registers(to_natural(i_dpath_rd)).value := (31 downto 1 => '0') & Bool2Bit(u32_t(opA) < u32_t(opB));
                        when "100" =>
                            registers(to_natural(i_dpath_rd)).value := opA xor opB;
                        when "101" =>
                            if (i_dpath_funct7 = "0100000") then -- SRA
                                registers(to_natural(i_dpath_rd)).value := std_logic_vector(s32_t(opA) sra to_natural(opB));
                            else -- SRL
                                registers(to_natural(i_dpath_rd)).value := std_logic_vector(u32_t(opA) srl to_natural(opB));
                            end if;
                        when "110" =>
                            registers(to_natural(i_dpath_rd)).value := opA or opB;
                        when "111" =>
                            registers(to_natural(i_dpath_rd)).value := opA and opB;
                        when others =>
                            assert false report "Invalid funct for ALUOP";
                    end case;
                end if;
            when cAluImmedOpcode =>
                case i_dpath_funct3 is
                    when "000" =>
                        registers(to_natural(i_dpath_rd)).value := std_logic_vector(s32_t(opA) + to_s32(i_dpath_itype));
                    when "001" => -- SLLI
                        registers(to_natural(i_dpath_rd)).value := std_logic_vector(u32_t(opA) sll to_natural(i_dpath_rs2));
                    when "010" =>
                        registers(to_natural(i_dpath_rd)).value := (31 downto 1 => '0') & Bool2Bit(s32_t(opA) < to_s32(i_dpath_itype));
                    when "011" =>
                        registers(to_natural(i_dpath_rd)).value := (31 downto 1 => '0') & Bool2Bit(u32_t(opA) < to_u32(i_dpath_itype));
                    when "100" =>
                        registers(to_natural(i_dpath_rd)).value := opA xor std_logic_vector(to_s32(i_dpath_itype));
                    when "101" =>
                        if (i_dpath_funct7 = "0100000") then -- SRAI
                            registers(to_natural(i_dpath_rd)).value := std_logic_vector(s32_t(opA) sra to_natural(i_dpath_rs2));
                        else -- SRLI
                            registers(to_natural(i_dpath_rd)).value := std_logic_vector(u32_t(opA) srl to_natural(i_dpath_rs2));
                        end if;
                    when "110" =>
                        registers(to_natural(i_dpath_rd)).value := opA or std_logic_vector(to_s32(i_dpath_itype));
                    when "111" =>
                        registers(to_natural(i_dpath_rd)).value := opA and std_logic_vector(to_s32(i_dpath_itype));
                    when others =>
                        assert false report "Invalid funct for ALUIMMED";
                end case;
            when cJumpOpcode =>
                o_dpath_nxtpc <= std_logic_vector(s32_t(i_dpath_pc) + to_s32(i_dpath_jtype));
                registers(to_natural(i_dpath_rd)).value := std_logic_vector(s32_t(i_dpath_pc) + 4);
            when cJumpRegOpcode =>
                o_dpath_nxtpc <= std_logic_vector(s32_t(opA) + to_s32(i_dpath_itype));
            when cLoadUpperOpcode =>
                registers(to_natural(i_dpath_rd)).value := i_dpath_utype & x"000";
                o_dpath_done  <= '1';
            when cAuipcOpcode =>
                lui_result := i_dpath_utype & x"000";
                registers(to_natural(i_dpath_rd)).value := std_logic_vector(unsigned(i_dpath_pc) + 
                    unsigned(lui_result));
                o_dpath_done  <= '1';
            when cFenceOpcode =>
                assert false report "Ecalls unsupported.";
            when cEcallOpcode =>
                assert false report "Ecalls unsupported.";
            when others =>
                assert false report "Invalid opcode";
        end case;
    end procedure;
    
end package body RiscVTbTools;