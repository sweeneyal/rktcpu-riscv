library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilityPkg.all;

entity tb_MExtensionUnit is
    generic (runner_cfg : string);
end entity tb_MExtensionUnit;

architecture tb of tb_MExtensionUnit is
    signal clk    : std_logic;
    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal funct7 : std_logic_vector(6 downto 0);
    signal opA    : std_logic_vector(31 downto 0);
    signal opB    : std_logic_vector(31 downto 0);
    signal result : std_logic_vector(31 downto 0);
    signal done   : std_logic
begin
    
    CreateClock(clock=>clk, period=>5 ns);

    eMExtension : MExtensionUnit
    port map (
        i_clk    => clk,
        i_opcode => opcode,
        i_funct3 => funct3,
        i_funct7 => funct7,
        i_opA    => opA,
        i_opB    => opB,
        o_result => meresult,
        o_done   => medone
    );

    Stimuli: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("t_mext") then
                
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;