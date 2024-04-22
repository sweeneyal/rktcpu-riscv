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

library tb;
    use tb.RiscVTbTools.all;

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
        variable RandData  : RandomPType;
        variable registers : register_map_t;
        variable pc_v      : natural;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            -- We need to verify the following:
            --     Decode behavior
            --     Instruction Request behavior
            --     PC update behavior
            if run("t_decode") then
                registers := generate_registers(x"00000001");
                resetn <= '0';
                instr  <= generate_instruction(registers);
                ivalid <= '0';
                done   <= '0';
                jtaken <= '0';
                btaken <= '0';
                nxtpc  <= x"00000000";
                
                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';
                wait for 100 ps;
                check(ren = '1');

                wait until rising_edge(clk);
                wait for 100 ps;
                ivalid <= '1';

                wait until rising_edge(clk);
                wait for 100 ps;
                ivalid <= '0';
                check(ren    = '0');
                check(opcode = instr(6 downto 0));
                check(rs1    = instr(19 downto 15));
                check(rs2    = instr(24 downto 20));
                check(rd     = instr(11 downto 7));
                check(funct3 = instr(14 downto 12));
                check(funct7 = instr(31 downto 25));
                check(itype  = instr(31 downto 20));
                check(stype  = instr(31 downto 25) & instr(11 downto 7));
                check(btype  = instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0');
                check(utype  = instr(31 downto 12));
                check(jtype  = instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & '0');
            elsif run("t_instr_req") then
                -- Create the environment
                registers := generate_registers(x"00000001");
                resetn <= '0';
                instr  <= generate_instruction(registers);
                ivalid <= '0';
                done   <= '0';
                jtaken <= '0';
                btaken <= '0';
                nxtpc  <= x"00000000";
                
                -- Apply and unapply reset.
                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';
                wait for 100 ps;
                check(ren = '1'); -- We should start requesting immediately

                for ii in 0 to 31 loop
                    wait until rising_edge(clk);
                    wait for 100 ps;
                    ivalid <= '1'; -- Request response
                    done   <= '0';
                    wait for 100 ps;
                    check(ren = '0');
    
                    wait until rising_edge(clk);
                    wait for 100 ps;
                    done <= '1'; -- Instruction done
                    wait for 100 ps;
                    -- As soon as the instruction is done, we should be 
                    -- making another request.
                    check(ren = '1');
                end loop;

            elsif run("t_pc_update") then
                -- Create the environment
                registers := generate_registers(x"00000001");
                resetn <= '0';
                instr  <= generate_instruction(registers, get_opcode_index(cBranchOpcode));
                ivalid <= '0';
                done   <= '0';
                jtaken <= '0';
                btaken <= '0';
                nxtpc  <= x"00000000";
                pc_v   := 0;
                
                -- Apply and unapply reset.
                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';
                wait for 100 ps;
                check(ren = '1'); -- We should start requesting immediately

                for ii in 0 to 31 loop
                    wait until rising_edge(clk);
                    wait for 100 ps;
                    --report "Pc should be " & natural'image(pc_v);
                    --report "Pc currently is " & natural'image(to_natural(pc));
                    check(pc = to_slv(pc_v, 32));
                    check(pcwen = '0');
                    ivalid <= '1'; -- Request response
                    done   <= '0';
                    wait for 100 ps;
                    check(ren = '0');
    
                    wait until rising_edge(clk);
                    wait for 100 ps;
                    done <= '1'; -- Instruction done
                    wait for 100 ps;
                    -- As soon as the instruction is done, we should be 
                    -- making another request.
                    check(ren = '1');
                    pc_v := pc_v + 1;
                end loop;

                wait until rising_edge(clk);
                wait for 100 ps;
                ivalid <= '1'; -- Request response
                done   <= '0';
                wait for 100 ps;
                check(ren = '0');

                wait until rising_edge(clk);
                wait for 100 ps;
                nxtpc  <= x"FFFF0000";
                btaken <= '1';
                done   <= '1'; -- Instruction done
                wait for 100 ps;
                -- As soon as the instruction is done, we should be 
                -- making another request, as well as indicating a new PC.
                check(pcwen = '1');
                check(ren = '1');
                wait until rising_edge(clk);
                wait for 100 ps;
                done <= '0'; -- Instruction done
                check(pc = x"FFFF0000");
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;