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
            -- Need to add verification to the address reading.
            if run("t_zicsr") then
                resetn  <= '0';
                opcode  <= cEcallOpcode;
                csraddr <= x"304";
                rd      <= "00000";
                rs1     <= "00000";
                opA     <= x"00000001";
                instret <= '0';
                funct3  <= "000";

                wait until rising_edge(clk);
                wait for 100 ps;
                resetn <= '1';

                -- Funct3 options
                -- 0 -> not a csr read, actually just an ecall.
                --      csrdone should not be set, csrren should not be set, and 
                --      ideally the csrr value will not change.
                -- 1 -> this is a write instruction
                -- 2 -> this is a set instruction
                -- 3 -> this is a clear instruction
                -- 4-7 -> are the same as above but using an immediate.
                wait until rising_edge(clk);
                wait for 100 ps;
                
                for jj in 0 to 1 loop
                    if (jj = 1) then
                        rd <= "00001";
                    end if;
                    for ii in 0 to 7 loop
                        funct3 <= to_slv(ii, 3);
                        wait until rising_edge(clk);
                        wait for 100 ps;

                        if ii = 0 or ii = 4 then
                            for kk in 0 to 3 loop
                                --report "csrren="&std_logic'image(csrren);
                                --report "csrdone="&std_logic'image(csrdone);
                                check(csrren = '0');
                                check(csrdone = '0');
                                wait until rising_edge(clk);
                                wait for 100 ps;
                            end loop;
                            report "Funct3=" & natural'image(ii) & "verified";
                        else
                            case (ii mod 4) is
                                when 1 =>
                                    if (rd = "00000") then
                                        -- First cc is a read, but since rd is 0, 
                                        -- we wont actually read.
                                        --report "csrren="&std_logic'image(csrren);
                                        --report "csrdone="&std_logic'image(csrdone);
                                        check(csrren = '0');
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        --report "csrdone="&std_logic'image(csrdone);
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        --report "csrdone="&std_logic'image(csrdone);
                                        check(csrdone = '1');
                                        report "Funct3=" & natural'image(ii) & "verified";
                                    else
                                        --report "csrdone="&std_logic'image(csrdone);
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        --report "csrren="&std_logic'image(csrren);
                                        check(csrren = '1');
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '1');
                                        report "Funct3=" & natural'image(ii) & "verified";
                                    end if;
                                when 2 =>
                                    if (rd = "00000") then
                                        -- First cc is a read, but since rd is 0, 
                                        -- we wont actually read.
                                        check(csrren = '0');
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '1');
                                        report "Funct3=" & natural'image(ii) & "verified";
                                    else
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        --report "csrren="&std_logic'image(csrren);
                                        check(csrren = '1');
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '1');
                                        report "Funct3=" & natural'image(ii) & "verified";
                                    end if;
                                when 3 =>
                                    if (rd = "00000") then
                                        -- First cc is a read, but since rd is 0, 
                                        -- we wont actually read.
                                        check(csrren = '0');
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '1');
                                        report "Funct3=" & natural'image(ii) & "verified";
                                    else
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        --report "csrren="&std_logic'image(csrren);
                                        check(csrren = '1');
                                        check(csrdone = '0');
                                        wait until rising_edge(clk);
                                        wait for 100 ps;
                                        check(csrdone = '1');
                                        report "Funct3=" & natural'image(ii) & "verified";
                                    end if;
                                when others =>
                                    assert false;
                            end case;
                        end if;
                    end loop;
                end loop;
            elsif run("t_address_read_write") then
                check(false);
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process Stimuli;
    
end architecture tb;