library vunit_lib;
    context vunit_lib.vunit_context;

entity tb_Alu is
    generic (runner_cfg : string);
end entity tb_Alu;

architecture tb of tb_Alu is
    signal opcode    : std_logic_vector(6 downto 0);
    signal funct3    : std_logic_vector(2 downto 0);
    signal funct7    : std_logic_vector(6 downto 0);
    signal itype     : std_logic_vector(11 downto 0);
    signal opA       : std_logic_vector(31 downto 0);
    signal opB       : std_logic_vector(31 downto 0);
    signal aluresult : std_logic_vector(31 downto 0);
    signal aluvalid  : std_logic;

    impure function rand_slv(len : integer) return std_logic_vector is
        variable r : real;
        variable slv : std_logic_vector(len - 1 downto 0);
    begin
        for i in slv'range loop
            uniform(seed1, seed2, r);
            slv(i) := '1' when r > 0.5 else '0';
        end loop;
        return slv;
    end function;
begin

    CreateClock(clock=>clk, period=>5 ns);
    
    eDut : Alu
    port map (
        i_opcode => opcode
        i_funct3 => funct3
        i_funct7 => funct7
        i_itype  => itype
        i_opA    => opA
        i_opB    => opB
        i_shamt  => rs2

        o_res    => aluresult,
        o_valid  => aluvalid
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_standard_reg") then
                opcode <= cAluOpcode;
                opA    <= rand_slv(32);
                opB    <= rand_slv(32);
                rs2    <= rand_slv(5);
                itype  <= (others => '0');
                for ii in 0 to 7 loop
                    funct3 <= to_slv(ii, 3);
                    funct7 <= "0000000";
                    
                    case ii is
                        when 0 => -- ADD
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(signed(opA) + signed(opB)) = aluresult);
                            check(aluvalid = '1');
                            
                            -- SUB
                            funct7 <= "0100000";
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(signed(opA) - signed(opB)) = aluresult);
                            check(aluvalid = '1');
                            
                        when 1 => -- SLL
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(unsigned(opA) sll to_natural(opB)) = aluresult);
                            check(aluvalid = '1');

                        when 2 => -- SLT
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check((31 downto 1 => '0') & bool2bit(s32_t(opA) < s32_t(opB)));
                            check(aluvalid = '1');

                        when 3 => -- SLTU
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check((31 downto 1 => '0') & bool2bit(u32_t(opA) < u32_t(opB)));
                            check(aluvalid = '1');

                        when 4 => -- XOR
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(opA xor opB = aluresult);
                            check(aluvalid = '1');

                        when 5 => -- SRL
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(unsigned(opA) srl to_natural(opB)) = aluresult);
                            check(aluvalid = '1');
                            
                            -- SRA
                            funct7 <= "0100000";
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(signed(opA) sra to_natural(opB)) = aluresult);
                            check(aluvalid = '1');

                        when 6 => -- OR
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(opA or opB = aluresult);
                            check(aluvalid = '1');

                        when 7 => -- AND
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(opA and opB = aluresult);
                            check(aluvalid = '1');

                        when others =>
                            assert false report "This should never happen.";
                    
                    end case;
                end loop;
                
            elsif run("t_standard_immed") then
                opcode <= cAluImmedOpcode;
                opA    <= rand_slv(32);
                opB    <= (others => '0');
                rs2    <= rand_slv(5);
                itype  <= rand_slv(12);

                for ii in 0 to 7 loop
                    funct3 <= to_slv(ii, 3);
                    
                    case ii is
                        when 0 => -- ADDI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(signed(opA) + resize(signed(itype), 32)) = aluresult);
                            check(aluvalid = '1');
                            
                        when 1 => -- SLLI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(u32_t(i_opA) sll to_natural(i_shamt)) = aluresult);
                            check(aluvalid = '1');

                        when 2 => -- SLTI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check((31 downto 1 => '0') & bool2bit(s32_t(opA) < to_s32(itype)));
                            check(aluvalid = '1');

                        when 3 => -- SLTUI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check((31 downto 1 => '0') & bool2bit(u32_t(opA) < to_u32(itype)));
                            check(aluvalid = '1');

                        when 4 => -- XORI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(opA xor std_logic_vector(to_s32(itype)) = aluresult);
                            check(aluvalid = '1');

                        when 5 => -- SRLI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(unsigned(opA) srl to_natural(rs2)) = aluresult);
                            check(aluvalid = '1');
                            funct7 <= "0100000";

                            -- SRAI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(std_logic_vector(signed(opA) sra to_natural(rs2)) = aluresult);
                            check(aluvalid = '1');

                        when 6 =>
                            -- ORI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(opA or std_logic_vector(to_s32(itype)) = aluresult);
                            check(aluvalid = '1');

                        when 7 =>
                            -- ANDI
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(opA and std_logic_vector(to_s32(itype)) = aluresult);
                            check(aluvalid = '1');

                        when others =>
                            assert false report "This should never happen.";
                    
                    end case;
                end loop;

            elsif run("t_illegal_decodes") then
                assert false report "It fails";
            end if;
        end loop;
        test_runner_cleanup(runner);
        -- then test illegal funct3s and funct7s
        -- then test the bad opcodes
        -- reiterate a few times.
    end process Stimuli;
    
end architecture tb;