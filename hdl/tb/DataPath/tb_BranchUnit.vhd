library vunit_lib;
    context vunit_lib.vunit_context;

entity tb_BranchUnit is
    generic (runner_cfg : string);
end entity tb_BranchUnit;

architecture tb of tb_BranchUnit is
    signal pc     : in std_logic_vector(31 downto 0);
    signal opcode : in std_logic_vector(6 downto 0);
    signal funct3 : in std_logic_vector(2 downto 0);
    signal itype  : in std_logic_vector(11 downto 0);
    signal jtype  : in std_logic_vector(20 downto 0);
    signal btype  : in std_logic_vector(12 downto 0);
    signal opA    : in std_logic_vector(31 downto 0);
    signal opB    : in std_logic_vector(31 downto 0);

    signal nxtpc  : out std_logic_vector(31 downto 0);
    signal pjpc   : out std_logic_vector(31 downto 0);
    signal btaken : out std_logic;
    signal jtaken : out std_logic;
    signal done   : out std_logic;
begin
    
    eDut : BranchUnit
    port map (
        i_pc     => pc,
        i_opcode => opcode,
        i_funct3 => funct3,
        i_itype  => itype,
        i_jtype  => jtype,
        i_btype  => btype,
        i_opA    => opA,
        i_opB    => opB,

        o_nxtpc  => nxtpc,
        o_pjpc   => pjpc,
        o_btaken => btaken,
        o_jtaken => jtaken,
        o_done   => bdone
    );
    
    Stimuli: process
    begin
        -- generate random 32 bit numbers for opA and opB
        -- iterate between all legal funct3s and funct7s for both opcode types
        -- then test illegal funct3s and funct7s
        -- then test the bad opcodes
        -- reiterate a few times.
    end process Stimuli;
    
end architecture tb;