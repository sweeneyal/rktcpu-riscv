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
    use scrv.ControlEntities.all;

entity tb_ExecuteEngine is
    generic (runner_cfg : string);
end entity tb_ExecuteEngine;

architecture tb of tb_ExecuteEngine is
    signal clk    : std_logic;
    signal resetn : std_logic;
    signal ren    : std_logic;
    signal instr  : std_logic_vector(31 downto 0);
    signal ivalid : std_logic;
    signal pcwen  : std_logic;
    signal pc     : std_logic_vector(31 downto 0);
    signal opcode : std_logic_vector(6 downto 0);
    signal rs1    : std_logic_vector(4 downto 0);
    signal rs2    : std_logic_vector(4 downto 0);
    signal rd     : std_logic_vector(4 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal funct7 : std_logic_vector(6 downto 0);
    signal itype  : std_logic_vector(11 downto 0);
    signal stype  : std_logic_vector(11 downto 0);
    signal btype  : std_logic_vector(12 downto 0);
    signal utype  : std_logic_vector(19 downto 0);
    signal jtype  : std_logic_vector(20 downto 0);
    signal done   : std_logic;
    signal jtaken : std_logic;
    signal btaken : std_logic;
    signal nxtpc  : std_logic_vector(31 downto 0);
begin
    
    CreateClock(clk=>clk, period=>5 ns);

    eDut : ExecuteEngine
    port map (
        i_clk    => clk,
        i_resetn => resetn,
        o_ren    => ren,
        i_instr  => instr,
        i_ivalid => ivalid,

        o_pcwen  => pcwen,
        o_pc     => pc,
        o_opcode => opcode,
        o_rs1    => rs1,
        o_rs2    => rs2,
        o_rd     => rd,
        o_funct3 => funct3,
        o_funct7 => funct7,
        o_itype  => itype,
        o_stype  => stype,
        o_btype  => btype,
        o_utype  => utype,
        o_jtype  => jtype,

        i_done   => done,
        i_jtaken => jtaken,
        i_btaken => btaken,
        i_nxtpc  => nxtpc
    );

    Stimuli: process
        variable RandData : RandomPType;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            -- We need to verify the following:
            --     Decode behavior
            --     Instruction Request behavior
            --     PC update behavior
            if run("t_decode") then
                resetn <= '0';
                instr  <= RandData.RandSlv(x"00000000", x"FFFFFFFF");
                ivalid <= '0';
                done   <= '0';
                jtaken <= '0';
                btaken <= '0';
                nxtpc  <= RandData.RandSlv(x"00000000", x"FFFFFFFF");
                check(false);
            elsif run("t_instr_req") then
                check(false);
            elsif run("t_pc_update") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;