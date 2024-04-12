library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library scrv;
    use scrv.Control.all;

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
    type state_t is (EX_RESET, EX_REQUEST, EX_EXECUTE, EX_SYSTEM);
    type execute_engine_t is record
        state : state_t;
        pc    : unsigned(31 downto 0);
        instr : std_logic_vector(31 downto 0);
    end record execute_engine_t;
    signal execute_engine : execute_engine_t;

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
begin
    
    opcode <= get_opcode(execute_engine.instr);
    rs1    <= get_funct3(execute_engine.instr);
    rs2    <= get_funct7(execute_engine.instr);
    rd     <= get_rs1(execute_engine.instr);
    funct3 <= get_rs2(execute_engine.instr);
    funct7 <= get_rd(execute_engine.instr);
    itype  <= get_itype(execute_engine.instr);
    stype  <= get_stype(execute_engine.instr);
    btype  <= get_btype(execute_engine.instr);
    utype  <= get_utype(execute_engine.instr);
    jtype  <= get_jtype(execute_engine.instr);

    StateMachine: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                execute_engine.state <= EX_RESET;
            else
                case execute_engine.state is
                    when EX_RESET =>
                        execute_engine.state <= EX_REQUEST;
                
                    when EX_REQUEST =>
                        if (i_valid = '1') then
                            execute_engine.instr <= i_instr;
                            execute_engine.state <= EX_EXECUTE;
                        end if;

                    when EX_EXECUTE =>
                        if (opcode = cEcallOpcode) then
                            execute_engine.state <= EX_SYSTEM;
                        elsif (opcode = cFenceOpcode) then
                            -- TODO: Fences need to be supported for any parallelism
                            execute_engine.state <= EX_REQUEST;
                        elsif (i_done = '1') then
                            execute_engine.state <= EX_REQUEST;

                            o_pcwen <= i_pcwen;
                            if (i_jtaken or i_btaken) then
                                execute_engine.pc <= unsigned(i_nxtpc);
                            end if;
                        end if;

                    when EX_SYSTEM =>
                        if to_natural(funct3) > 0 then
                            if (i_done = '1') then
                                execute_engine.state <= EX_REQUEST;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process StateMachine;

    OutputRegisters: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                o_opcode <= (others => '0');
                o_rs1    <= (others => '0');
                o_rs2    <= (others => '0');
                o_rd     <= (others => '0');
                o_funct3 <= (others => '0');
                o_funct7 <= (others => '0');
                o_itype  <= (others => '0');
                o_stype  <= (others => '0');
                o_btype  <= (others => '0');
                o_utype  <= (others => '0');
                o_jtype  <= (others => '0');
            else
                if execute_engine.state = EX_REQUEST or 
                        execute_engine.state = EX_RESET then
                    o_opcode <= (others => '0');
                    o_rs1    <= (others => '0');
                    o_rs2    <= (others => '0');
                    o_rd     <= (others => '0');
                    o_funct3 <= (others => '0');
                    o_funct7 <= (others => '0');
                    o_itype  <= (others => '0');
                    o_stype  <= (others => '0');
                    o_btype  <= (others => '0');
                    o_utype  <= (others => '0');
                    o_jtype  <= (others => '0');
                else
                    o_opcode <= opcode;
                    o_rs1    <= rs1;
                    o_rs2    <= rs2;
                    o_rd     <= rd;
                    o_funct3 <= funct3;
                    o_funct7 <= funct7;
                    o_itype  <= itype;
                    o_stype  <= stype;
                    o_btype  <= btype;
                    o_utype  <= utype;
                    o_jtype  <= jtype;
                end if;
            end if;
        end if;
    end process OutputRegisters;
    
end architecture rtl;