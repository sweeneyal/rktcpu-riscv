library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.ControlEntities.all;
    use scrv.RiscVDefinitions.all;

entity ExecuteEngine is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        o_ren    : out std_logic;
        i_instr  : out std_logic_vector(31 downto 0);
        i_ivalid : out std_logic;
        
        o_pcwen  : out std_logic;
        o_pc     : out std_logic_vector(31 downto 0);
        o_opcode : out std_logic_vector(6 downto 0);
        o_rs1    : out std_logic_vector(4 downto 0);
        o_rs2    : out std_logic_vector(4 downto 0);
        o_rd     : out std_logic_vector(4 downto 0);
        o_funct3 : out std_logic_vector(2 downto 0);
        o_funct7 : out std_logic_vector(6 downto 0);
        o_itype  : out std_logic_vector(11 downto 0);
        o_stype  : out std_logic_vector(11 downto 0);
        o_btype  : out std_logic_vector(12 downto 0);
        o_utype  : out std_logic_vector(19 downto 0);
        o_jtype  : out std_logic_vector(20 downto 0);

        i_done   : in std_logic;
        i_jtaken : in std_logic;
        i_btaken : in std_logic;
        i_nxtpc  : in std_logic_vector(31 downto 0)
    );
end entity ExecuteEngine;

architecture rtl of ExecuteEngine is
    type state_t is (EX_RESET, EX_EXECUTE, EX_SYSTEM);
    type execute_engine_t is record
        state : state_t;
        pc    : unsigned(31 downto 0);
        done  : std_logic;
    end record execute_engine_t;
    signal execute_engine : execute_engine_t;
    
    signal instr  : std_logic_vector(31 downto 0);
    signal ivalid : std_logic;

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

    signal pcwen : std_logic;
begin
    
    pcwen   <= i_jtaken or i_btaken;
    o_pcwen <= pcwen;
    -- Request new instruction when done with the previous one, when in the reset state and not actively being reset,
    -- or when 
    o_ren <= (i_done or execute_engine.done
        or bool2bit(execute_engine.state = EX_RESET)) and i_resetn;

    o_pc     <= std_logic_vector(execute_engine.pc);
    o_opcode <= get_opcode(instr);
    o_rd     <= get_rd(instr);
    o_rs1    <= get_rs1(instr);
    o_rs2    <= get_rs2(instr);
    o_funct3 <= get_funct3(instr);
    o_funct7 <= get_funct7(instr);
    o_itype  <= get_itype(instr);
    o_stype  <= get_stype(instr);
    o_btype  <= get_btype(instr);
    o_utype  <= get_utype(instr);
    o_jtype  <= get_jtype(instr);

    InstructionRegister: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_ivalid = '1') then
                instr  <= i_instr;
                ivalid <= '1';
            elsif (i_done = '1' or execute_engine.done = '1') then
                instr  <= x"00000000";
                ivalid <= '0';
            end if;
        end if;
    end process InstructionRegister;

    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                execute_engine.state <= EX_RESET;
                execute_engine.done  <= '0';
                execute_engine.pc    <= x"00000000";
            else
                case execute_engine.state is
                    when EX_RESET =>
                        execute_engine.state <= EX_EXECUTE;
                        execute_engine.done <= '0';

                    when EX_EXECUTE =>
                        execute_engine.done <= '0';
                        if (ivalid = '1') then
                            if (opcode = cEcallOpcode) then
                                execute_engine.state <= EX_SYSTEM;
                            elsif (opcode = cFenceOpcode) then
                                -- TODO: Fences need to be supported for any parallelism
                                execute_engine.done <= '1';
                                execute_engine.pc   <= execute_engine.pc + to_unsigned(1, 32);
                            elsif (i_done = '1') then
                                if (pcwen = '1') then
                                    execute_engine.pc <= unsigned(i_nxtpc);
                                else
                                    execute_engine.pc <= execute_engine.pc + to_unsigned(1, 32);
                                end if;
                            end if;
                        end if;

                    when EX_SYSTEM =>
                        if to_natural(funct3) > 0 then
                            if (i_done = '1') then
                                execute_engine.state <= EX_EXECUTE;
                                execute_engine.pc <= execute_engine.pc + to_unsigned(1, 32);
                            end if;
                        else
                            execute_engine.done <= '1';
                            execute_engine.pc <= execute_engine.pc + to_unsigned(1, 32);
                        end if;
                end case;
            end if;
        end if;
    end process StateMachine;
    
end architecture rtl;