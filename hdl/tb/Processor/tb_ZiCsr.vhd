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

library rktcpu;
    use rktcpu.RktCpuDefinitions.all;
    use rktcpu.RiscVDefinitions.all;
    use rktcpu.CsrDefinitions.all;

library tb;
    use tb.RiscVTbTools.all;

entity tb_ZiCsr is
    generic (
        runner_cfg : string
    );
end entity tb_ZiCsr;

architecture tb of tb_ZiCsr is
    signal clk_i       : std_logic := '0';
    signal resetn_i    : std_logic := '0';
    signal ctrl_zcsr_i : zicsr_controls_t;
    signal opA_i       : std_logic_vector(31 downto 0) := x"00000000";
    signal csrr_o      : std_logic_vector(31 downto 0) := x"00000000";
    signal csrren_o    : std_logic := '0';
    signal csrdone_o   : std_logic := '0';
    signal instret_i   : std_logic := '0';
    signal swirpt_i    : std_logic := '0';
    signal extirpt_i   : std_logic := '0';
    signal tmrirpt_i   : std_logic := '0';
    signal irpts_i     : std_logic_vector(15 downto 0) := x"0000";
    signal irptvalid_o : std_logic := '0';
    signal irptpc_o    : std_logic_vector(31 downto 0) := x"00000000";
    signal mepc_o      : std_logic_vector(31 downto 0) := x"00000000";
    signal mepcvalid_o : std_logic := '0';
begin
    
    CreateClock(clk=>clk_i, period=>5 ns);

    eDut : entity rktcpu.ZiCsr
    generic map (
        cTrapBaseAddress => x"00010000"
    ) port map (
        i_clk => clk_i,
        i_resetn => resetn_i,

        i_ctrl_zcsr => ctrl_zcsr_i,
        i_opA       => opA_i,
        o_csrr      => csrr_o,
        o_csrren    => csrren_o,
        o_csrdone   => csrdone_o,
        i_instret   => instret_i,

        i_swirpt  => swirpt_i,
        i_extirpt => extirpt_i,
        i_tmrirpt => tmrirpt_i,
        i_irpts   => irpts_i,

        o_irptvalid => irptvalid_o,
        o_irptpc    => irptpc_o,

        o_mepc      => mepc_o,
        o_mepcvalid => mepcvalid_o
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_standard") then
                resetn_i <= '0';

                wait until rising_edge(clk_i);
                wait for 100 ps;

                resetn_i <= '1';

                wait until rising_edge(clk_i);
                wait for 100 ps;
                
                ctrl_zcsr_i.en     <= '1';
                ctrl_zcsr_i.rs1    <= "00001";
                ctrl_zcsr_i.rd     <= "00000";
                ctrl_zcsr_i.funct3 <= "001";
                ctrl_zcsr_i.itype  <= x"301";
                ctrl_zcsr_i.mret   <= '0';
                ctrl_zcsr_i.sret   <= '0';
                ctrl_zcsr_i.pc     <= x"00000000";
                opA_i              <= x"AAAAAAAA";

                wait until rising_edge(clk_i);
                wait for 100 ps;

                ctrl_zcsr_i.en     <= '0';

                wait until csrdone_o = '1';
                wait until rising_edge(clk_i);
                wait for 100 ps;

                ctrl_zcsr_i.en     <= '1';
                ctrl_zcsr_i.rs1    <= "00000";
                ctrl_zcsr_i.rd     <= "00001";
                ctrl_zcsr_i.funct3 <= "010";
                ctrl_zcsr_i.itype  <= x"301";
                opA_i              <= x"00000000";

                wait until csrdone_o = '1';
                check(csrr_o = x"AAAAAAAA");
                wait until rising_edge(clk_i);
                wait for 100 ps;

                --check(false);
            elsif run("t_interrupts") then
                resetn_i <= '0';

                wait until rising_edge(clk_i);
                wait for 100 ps;

                resetn_i <= '1';

                wait until rising_edge(clk_i);
                wait for 100 ps;
                
                ctrl_zcsr_i.en     <= '1';
                ctrl_zcsr_i.rs1    <= "00001";
                ctrl_zcsr_i.rd     <= "00000";
                ctrl_zcsr_i.funct3 <= "001";
                ctrl_zcsr_i.itype  <= x"304";
                ctrl_zcsr_i.mret   <= '0';
                ctrl_zcsr_i.sret   <= '0';
                ctrl_zcsr_i.pc     <= x"00000000";
                opA_i              <= (others => '0');
                opA_i(cMTI)        <= '1';

                wait until rising_edge(clk_i);
                wait for 100 ps;

                ctrl_zcsr_i.en     <= '0';

                wait until csrdone_o = '1';
                wait until rising_edge(clk_i);
                wait for 100 ps;

                wait until rising_edge(clk_i);
                wait for 100 ps;
                
                ctrl_zcsr_i.en     <= '1';
                ctrl_zcsr_i.rs1    <= "00001";
                ctrl_zcsr_i.rd     <= "00000";
                ctrl_zcsr_i.funct3 <= "001";
                ctrl_zcsr_i.itype  <= x"300";
                ctrl_zcsr_i.mret   <= '0';
                ctrl_zcsr_i.sret   <= '0';
                ctrl_zcsr_i.pc     <= x"00000000";
                opA_i              <= (others => '0');
                opA_i(cMIE)        <= '1';

                wait until rising_edge(clk_i);
                wait for 100 ps;

                ctrl_zcsr_i.en     <= '0';

                wait until csrdone_o = '1';
                wait until rising_edge(clk_i);
                wait for 100 ps;

                wait until rising_edge(clk_i);
                wait for 100 ps;

                wait until rising_edge(clk_i);
                wait for 100 ps;

                tmrirpt_i <= '1';
                wait until rising_edge(clk_i);
                wait for 100 ps;
                tmrirpt_i <= '0';

                wait until irptvalid_o = '1';
                check(unsigned(irptpc_o) = to_natural(x"00010000") + (7 * 4));
            elsif run("t_unique") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;