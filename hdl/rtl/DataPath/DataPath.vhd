library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;
    use universal.CommonTypesPkg.all;

library scrv;
    use scrv.DataPathEntities.all;
    use scrv.RiscVDefinitions.all;

entity DataPath is
    port (
        i_clk    : in std_logic;
        i_pc     : in std_logic_vector(31 downto 0);
        i_opcode : in std_logic_vector(2 downto 0);

        -- Decoder signals
        i_rs1    : in std_logic_vector(4 downto 0);
        i_rs2    : in std_logic_vector(4 downto 0);
        i_rd     : in std_logic_vector(4 downto 0);
        i_funct3 : in std_logic_vector(2 downto 0);
        i_funct7 : in std_logic_vector(6 downto 0);
        i_itype  : in std_logic_vector(11 downto 0);
        i_stype  : in std_logic_vector(11 downto 0);
        i_btype  : in std_logic_vector(12 downto 0);
        i_utype  : in std_logic_vector(19 downto 0);
        i_jtype  : in std_logic_vector(20 downto 0);
        i_csrren : in std_logic;
        i_csrr   : in std_logic_vector(31 downto 0);
        
        -- Result and program counter control
        o_nxtpc  : out std_logic_vector(31 downto 0);
        o_btaken : out std_logic;
        o_jtaken : out std_logic;
        o_result : out std_logic_vector(31 downto 0);
        o_csrwen : out std_logic;
        o_csrw   : out std_logic_vector(31 downto 0);
        o_done   : out std_logic;

        -- Memory access signals
        o_addr    : out std_logic_vector(31 downto 0);
        o_wdata   : out std_logic_vector(31 downto 0);
        o_maccess : out std_logic_vector(2 downto 0);
        o_men     : out std_logic;
        o_mwen    : out std_logic_vector(3 downto 0);

        i_maccess : out std_logic_vector(2 downto 0);
        i_rdata   : in std_logic_vector(31 downto 0);
        i_rvalid  : in std_logic
    );
end entity DataPath;

architecture rtl of DataPath is
    signal opA       : std_logic_vector(31 downto 0);
    signal opB       : std_logic_vector(31 downto 0);
    signal aluresult : std_logic_vector(31 downto 0);
    signal aluvalid  : std_logic;
    signal mresult   : std_logic_vector(31 downto 0);
    signal ldone     : std_logic;
begin
    
    eAlu : Alu
    port map (
        i_opcode => i_opcode
        i_funct3 => i_funct3
        i_funct7 => i_funct7
        i_itype  => i_itype
        i_opA    => opA
        i_opB    => opB
        i_shamt  => i_rs2

        o_res    => aluresult,
        o_valid  => aluvalid
    );

    eBranch : BranchUnit
    port map (
        i_pc     => i_pc,
        i_opcode => i_opcode,
        i_funct3 => i_funct3,
        i_rd     => i_rd,
        i_rs1    => i_rs1,
        i_itype  => i_itype,
        i_jtype  => i_jtype,
        i_btype  => i_btype,
        i_opA    => opA,
        i_opB    => opB,

        o_nxtpc  => nxtpc,
        o_pjpc   => pjpc,
        o_btaken => btaken,
        o_jtaken => jtaken
    );

    o_nxtpc  <= nxtpc;
    o_btaken <= btaken;
    o_jtaken <= jtaken;

    eMemUnit : MemAccessUnit
    port map (
        i_clk    => i_clk,
        i_opcode => i_opcode,
        i_opA    => opA,
        i_itype  => i_itype,
        i_stype  => i_stype,
        i_funct3 => i_funct3
        
        o_addr    => o_addr,
        o_men     => o_men,
        o_mwen    => o_mwen,

        i_rvalid => i_rvalid,
        i_rdata  => i_rdata,
        
        o_data  => mresult,
        o_ldone => ldone,
        o_sdone => sdone
        
    );

    ResultMux: process(aluvalid, aluresult, jtaken, pjpc, ldone, mresult, i_csrwen, i_csrw)
        variable state : std_logic_vector(2 downto 0);
    begin
        state := i_csrwen & aluvalid & jtaken & ldone;
        case state is
            when "0001" =>
                result <= mresult;

            when "0010" =>
                result <= pjpc;

            when "0100" =>
                result <= aluresult;

            when "1000" =>
                result <= i_csrw;

            when others =>
                result <= (others => '0');
        
        end case;
    end process ResultMux;
    wen      <= jtaken or aluvalid or i_csrwen or ldone;
    o_result <= result;
    o_done   <= wen or sdone;

    eRegisterFile : RegisterFile
    generic map (
        cDataWidth    => 32,
        cAddressWidth => 5
    ) port map (
        i_clk    => i_clk,
        i_resetn => i_resetn,

        i_rs1    => i_rs1,
        i_rs2    => i_rs2,
        i_rd     => i_rd,

        i_result => result,
        i_wen    => wen,

        o_opA    => opA,
        o_opB    => opB
    );

    i_csrw <= opA;
    
end architecture rtl;