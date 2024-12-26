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

library tb;
    use tb.RiscVTbTools.all;

entity tb_ControlEngine is
    generic (
        runner_cfg : string
    );
end entity tb_ControlEngine;

architecture tb of tb_ControlEngine is
    signal clk_i      : std_logic := '0';
    signal resetn_i   : std_logic := '0';

    signal pc_o      : std_logic_vector(31 downto 0) := x"00000000";
    signal iren_o    : std_logic := '0';
    signal instr_i   : std_logic_vector(31 downto 0) := x"00000000";
    signal ivalid_i  : std_logic := '0';
    signal en_o      : std_logic := '0';

    signal mvalid_i  : std_logic := '0';
    signal csrdone_i : std_logic := '0';

    signal ctrl_cmn_o  : common_controls_t;
    signal ctrl_alu_o  : alu_controls_t;
    signal ctrl_mem_o  : mem_controls_t;
    signal ctrl_brnc_o : branch_controls_t;
    signal ctrl_zcsr_o : zicsr_controls_t;
    signal ctrl_jal_o  : jal_controls_t;
    signal ctrl_dbg_o  : dbg_controls_t;

    signal pc_i      : std_logic_vector(31 downto 0) := x"00000000";
    signal pcwen_i   : std_logic := '0';
    signal irvalid_i : std_logic := '0';
begin
    
    CreateClock(clk=>clk_i, period=>5 ns);

    eControl : entity rktcpu.ControlEngine
    port map (
        i_clk     => clk_i,
        i_resetn  => resetn_i,
        o_pc      => pc_o,
        o_iren    => iren_o,
        i_instr   => instr_i,
        i_ivalid  => ivalid_i,
        i_mvalid  => mvalid_i,
        i_csrdone => csrdone_i,

        o_ctrl_cmn  => ctrl_cmn_o,
        o_ctrl_alu  => ctrl_alu_o,
        o_ctrl_mem  => ctrl_mem_o,
        o_ctrl_brnc => ctrl_brnc_o,
        o_ctrl_zcsr => ctrl_zcsr_o,
        o_ctrl_jal  => ctrl_jal_o,
        o_ctrl_dbg  => ctrl_dbg_o,

        i_pc      => pc_i, 
        i_pcwen   => pcwen_i,
        i_irvalid => irvalid_i
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_control") then
                check(false);
            elsif run("t_stalls") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;