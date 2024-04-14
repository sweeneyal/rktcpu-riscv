library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.RiscVDefinitions.all;
    use scrv.ControlEntities.all;

entity tb_ZiCsr is
    generic (runner_cfg : string);
end entity tb_ZiCsr;

architecture tb of tb_ZiCsr is
    signal clk     : std_logic;
    signal resetn  : std_logic;
    signal opcode  : std_logic_vector(6 downto 0);
    signal funct3  : std_logic_vector(2 downto 0);
    signal csraddr : std_logic_vector(11 downto 0);
    signal rd      : std_logic_vector(4 downto 0);
    signal rs1     : std_logic_vector(4 downto 0);
    signal opA     : std_logic_vector(31 downto 0);
    signal csrr    : std_logic_vector(31 downto 0);
    signal csrren  : std_logic;
    signal csrdone : std_logic;
    signal instret : std_logic;
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : ZiCsr
    port map (
        i_clk     => clk,
        i_resetn  => resetn,
        i_opcode  => opcode,
        i_funct3  => funct3,
        i_csraddr => csraddr,
        i_rd      => rd,
        i_rs1     => rs1,
        i_opA     => opA,
        o_csrr    => csrr,
        o_csrren  => csrren,
        o_csrdone => csrdone,
        i_instret => instret
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_zicsr") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;