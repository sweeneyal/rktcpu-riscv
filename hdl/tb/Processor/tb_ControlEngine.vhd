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
        encoded_tb_cfg : string;
        runner_cfg : string
    );
end entity tb_ControlEngine;

architecture tb of tb_ControlEngine is
    type tb_cfg_t is record
        instructions : string;
    end record tb_cfg_t;

    impure function decode (enc_tb_cfg : string) return tb_cfg_t is
    begin
        return (instructions=>get(enc_tb_cfg, "instructions"));
    end function;

    constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

    signal clk     : std_logic := '0';
    signal resetn  : std_logic := '0';
    signal o_pc    : std_logic_vector(31 downto 0) := x"00000000";
    signal iren    : std_logic := '0';
    signal instr   : std_logic_vector(31 downto 0) := x"00000000";
    signal ivalid  : std_logic := '0';
    signal mvalid  : std_logic := '0';
    signal csrdone : std_logic := '0';

    signal ctrl_cmn  : common_controls_t;
    signal ctrl_alu  : alu_controls_t;
    signal ctrl_mem  : mem_controls_t;
    signal ctrl_brnc : branch_controls_t;
    signal ctrl_zcsr : zicsr_controls_t;
    signal ctrl_jal  : jal_controls_t;

    signal i_pc    : std_logic_vector(31 downto 0) := x"00000000";
    signal i_pcwen : std_logic := '0';
begin

    CreateClock(clk=>clk, period=>5 ns);
    
    eDut : entity rktcpu.ControlEngine
    port map (
        i_clk     => clk,
        i_resetn  => resetn,
        o_pc      => o_pc,
        o_iren    => iren,
        i_instr   => instr,
        i_ivalid  => ivalid,
        i_mvalid  => mvalid,
        i_csrdone => csrdone,

        o_ctrl_cmn  => ctrl_cmn,
        o_ctrl_alu  => ctrl_alu,
        o_ctrl_mem  => ctrl_mem,
        o_ctrl_brnc => ctrl_brnc,
        o_ctrl_zcsr => ctrl_zcsr,
        o_ctrl_jal  => ctrl_jal,

        i_pc    => i_pc, 
        i_pcwen => i_pcwen 
    );

    eImem : entity tb.InstructionMemory
    generic map (
        cInstructionHexPath => tb_cfg.instructions
    ) port map (
        i_clk          => clk,
        i_resetn       => resetn,
        i_instr_addr   => o_pc,
        i_instr_ren    => iren,
        i_instr_wen    => "0000",
        i_instr_wdata  => x"00000000",
        o_instr_rdata  => instr,
        o_instr_rvalid => ivalid
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_simple") then
                resetn <= '0';
                wait until rising_edge(clk);
                resetn <= '1';
                for ii in 0 to 10 loop
                    wait until rising_edge(clk);
                end loop;
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;