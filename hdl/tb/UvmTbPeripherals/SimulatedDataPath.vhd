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

library rktcpu;
    use rktcpu.RiscVDefinitions.all;

library tb;
    use tb.RiscVTbTools.all;

entity SimulatedDataPath is
    port (
        -- System level signals
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- Bus Signals
        o_data_addr   : out std_logic_vector(31 downto 0);
        o_data_ren    : out std_logic;
        o_data_wen    : out std_logic_vector(3 downto 0);
        o_data_wdata  : out std_logic_vector(31 downto 0);
        i_data_rdata  : in std_logic_vector(31 downto 0);
        i_data_rvalid : in std_logic;

        -- Datapath Signals
        i_dpath_pc     : in std_logic_vector(31 downto 0);
        i_dpath_opcode : in std_logic_vector(6 downto 0);
        i_dpath_rs1    : in std_logic_vector(4 downto 0);
        i_dpath_rs2    : in std_logic_vector(4 downto 0);
        i_dpath_rd     : in std_logic_vector(4 downto 0);
        i_dpath_funct3 : in std_logic_vector(2 downto 0);
        i_dpath_funct7 : in std_logic_vector(6 downto 0);
        i_dpath_itype  : in std_logic_vector(11 downto 0);
        i_dpath_stype  : in std_logic_vector(11 downto 0);
        i_dpath_btype  : in std_logic_vector(12 downto 0);
        i_dpath_utype  : in std_logic_vector(19 downto 0);
        i_dpath_jtype  : in std_logic_vector(20 downto 0);
        o_dpath_done   : out std_logic;
        o_dpath_jtaken : out std_logic;
        o_dpath_btaken : out std_logic;
        o_dpath_nxtpc  : out std_logic_vector(31 downto 0);

        -- Debug signals
        o_dbg_result : out std_logic_vector(31 downto 0);
        o_dbg_valid  : out std_logic
    );
end entity SimulatedDataPath;

architecture rtl of SimulatedDataPath is
begin
    
    DataPathSimulation: process(i_clk)
        variable registers : register_map_t := generate_registers(x"00000001");
        variable state     : memory_state_t := IDLE;
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                registers := generate_registers(x"00000001");
            else
                if (i_dpath_opcode = cLoadOpcode or i_dpath_opcode = cStoreOpcode) then
                    simulate_memory(
                        registers => registers,
                        state     => state,

                        -- Bus Signals
                        o_data_addr   => o_data_addr,
                        o_data_ren    => o_data_ren,
                        o_data_wen    => o_data_wen,
                        o_data_wdata  => o_data_wdata,
                        i_data_rdata  => i_data_rdata,
                        i_data_rvalid => i_data_rvalid,

                        -- Datapath Signals
                        i_dpath_pc     => i_dpath_pc,
                        i_dpath_opcode => i_dpath_opcode,
                        i_dpath_rs1    => i_dpath_rs1,
                        i_dpath_rs2    => i_dpath_rs2,
                        i_dpath_rd     => i_dpath_rd,
                        i_dpath_funct3 => i_dpath_funct3,
                        i_dpath_itype  => i_dpath_itype,
                        i_dpath_stype  => i_dpath_stype,
                        o_dpath_done   => o_dpath_done,
                        o_dpath_jtaken => o_dpath_jtaken,
                        o_dpath_btaken => o_dpath_btaken,
                        o_dpath_nxtpc  => o_dpath_nxtpc,
                        o_dbg_valid    => o_dbg_valid
                    );
                    
                    o_dbg_result <= registers(to_natural(i_dpath_rd)).value;
                else
                    simulate_instruction(
                        registers => registers,
    
                        o_data_addr   => o_data_addr,
                        o_data_ren    => o_data_ren,
                        o_data_wen    => o_data_wen,
                        o_data_wdata  => o_data_wdata,
                        i_data_rdata  => i_data_rdata,
                        i_data_rvalid => i_data_rvalid,
    
                        i_dpath_pc     => i_dpath_pc,
                        i_dpath_opcode => i_dpath_opcode,
                        i_dpath_rs1    => i_dpath_rs1,
                        i_dpath_rs2    => i_dpath_rs2,
                        i_dpath_rd     => i_dpath_rd,
                        i_dpath_funct3 => i_dpath_funct3,
                        i_dpath_funct7 => i_dpath_funct7,
                        i_dpath_itype  => i_dpath_itype,
                        i_dpath_stype  => i_dpath_stype,
                        i_dpath_btype  => i_dpath_btype,
                        i_dpath_utype  => i_dpath_utype,
                        i_dpath_jtype  => i_dpath_jtype,
                        o_dpath_done   => o_dpath_done,
                        o_dpath_jtaken => o_dpath_jtaken,
                        o_dpath_btaken => o_dpath_btaken,
                        o_dpath_nxtpc  => o_dpath_nxtpc,
                        o_dbg_valid    => o_dbg_valid
                    );
    
                    o_dbg_result <= registers(to_natural(i_dpath_rd)).value;
                end if;
            end if;
        end if;
    end process DataPathSimulation;
    
end architecture rtl;