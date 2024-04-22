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
    use scrv.DataPathEntities.all;

entity tb_BranchUnit is
    generic (runner_cfg : string);
end entity tb_BranchUnit;

architecture tb of tb_BranchUnit is
    signal clk    : std_logic;
    signal pc     : std_logic_vector(31 downto 0);
    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal itype  : std_logic_vector(11 downto 0);
    signal jtype  : std_logic_vector(20 downto 0);
    signal btype  : std_logic_vector(12 downto 0);
    signal opA    : std_logic_vector(31 downto 0);
    signal opB    : std_logic_vector(31 downto 0);

    signal nxtpc   : std_logic_vector(31 downto 0);
    signal pjpc    : std_logic_vector(31 downto 0);
    signal btaken  : std_logic;
    signal jtaken  : std_logic;
    signal bdone   : std_logic;
    signal bexcept : std_logic;
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : BranchUnit
    port map (
        i_pc     => pc,
        i_opcode => opcode,
        i_funct3 => funct3,
        i_itype  => itype,
        i_jtype  => jtype,
        i_btype  => btype,
        i_opA    => opA,
        i_opB    => opB,

        o_nxtpc   => nxtpc,
        o_pjpc    => pjpc,
        o_btaken  => btaken,
        o_jtaken  => jtaken,
        o_done    => bdone,
        o_bexcept => bexcept
    );
    
    Stimuli: process
        variable RandData : RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_branch") then
                pc     <= RandData.RandSlv(x"FFFFFFFF");
                opcode <= cBranchOpcode;
                opA    <= RandData.RandSlv(x"FFFFFFFF");
                opB    <= RandData.RandSlv(x"FFFFFFFF");
                itype  <= (others => '0');
                btype  <= RandData.RandSlv("1111111111111");

                -- Assert that pjpc is always pc + 4;
                for ii in 0 to 7 loop
                    funct3 <= to_slv(ii, 3);
                    
                    case ii is
                        when 0 => -- BEQ
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            if (signed(opA) = signed(opB)) then
                                check(btaken = '1');
                            else
                                check(btaken = '0');
                            end if;
                            check(bdone = '1');
                            check(bexcept = '0');
                            
                        when 1 => -- BNE
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            if (signed(opA) /= signed(opB)) then
                                check(btaken = '1');
                            else
                                check(btaken = '0');
                            end if;
                            check(bdone = '1');
                            check(bexcept = '0');

                        when 2 => -- Bad op
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(bdone   = '0');
                            check(bexcept = '1');

                        when 3 => -- Bad op
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            check(bdone   = '0');
                            check(bexcept = '1');

                        when 4 => -- BLT
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            if (signed(opA) < signed(opB)) then
                                check(btaken = '1');
                            else
                                check(btaken = '0');
                            end if;
                            check(bdone = '1');
                            check(bexcept = '0');

                        when 5 => -- BGE
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            if (signed(opA) >= signed(opB)) then
                                check(btaken = '1');
                            else
                                check(btaken = '0');
                            end if;
                            check(bdone = '1');
                            check(bexcept = '0');

                        when 6 => -- BLTU
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            if (unsigned(opA) < unsigned(opB)) then
                                check(btaken = '1');
                            else
                                check(btaken = '0');
                            end if;
                            check(bdone = '1');
                            check(bexcept = '0');

                        when 7 => -- BGEU
                            wait until rising_edge(clk);
                            wait for 100 ps;
                            if (unsigned(opA) >= unsigned(opB)) then
                                check(btaken = '1');
                            else
                                check(btaken = '0');
                            end if;
                            check(bdone = '1');
                            check(bexcept = '0');

                        when others =>
                            assert false report "This should never happen.";
                    
                    end case;

                end loop;
                
            elsif run("t_jump") then
                opcode <= cJumpOpcode;
                pc     <= RandData.RandSlv(x"FFFFFFFF");
                jtype  <= RandData.RandSlv(0, 2**21 - 1, 21);
                opA    <= (others => '0');
                opB    <= (others => '0');
                itype  <= (others => '0');
                btype  <= (others => '0');
                
                wait until rising_edge(clk);
                wait for 100 ps;
                check(nxtpc   = std_logic_vector(s32_t(pc) + to_s32(jtype)));
                check(pjpc    = std_logic_vector(s32_t(pc) + 4));
                check(jtaken  = '1');
                check(btaken  = '0');
                check(bdone   = '1');
                check(bexcept = '0');

            elsif run("t_jumpreg") then
                opcode <= cJumpRegOpcode;
                pc     <= RandData.RandSlv(x"FFFFFFFF");
                opA    <= RandData.RandSlv(x"FFFFFFFF");
                itype  <= RandData.RandSlv("111111111111");
                jtype  <= (others => '0');
                opB    <= (others => '0');
                btype  <= (others => '0');
                
                wait until rising_edge(clk);
                wait for 100 ps;
                check(nxtpc   = std_logic_vector(s32_t(opA) + to_s32(itype)));
                check(pjpc    = std_logic_vector(s32_t(pc) + 4));
                check(jtaken  = '1');
                check(btaken  = '0');
                check(bdone   = '1');
                check(bexcept = '0');

            elsif run("t_illegal_decodes") then
                assert false report "It fails";
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;