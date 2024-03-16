entity Scurvy is
    port (
        i_clk    : in std_logic;
        i_resetn : in std_logic;

        -- Bus for Instructions
        o_pc     : out std_logic_vector(31 downto 0);
        o_ren    : out std_logic;
        i_instr  : in std_logic_vector(31 downto 0);
        i_ivalid : in std_logic;
        
        -- Bus for Data
        o_addr    : out std_logic_vector(31 downto 0);
        o_en      : out std_logic;
        o_wen     : out std_logic;
        o_wdata   : out std_logic_vector(31 downto 0);
        o_maccess : out std_logic_vector(2 downto 0);
        i_maccess : in std_logic_vector(2 downto 0);
        i_rdata   : in std_logic_vector(31 downto 0);
        i_rvalid  : in std_logic
    );
end entity Scurvy;

architecture rtl of Scurvy is
    type control_out_t is record
        -- Decoder signals
        pc     : std_logic_vector(31 downto 0);
        opcode : std_logic_vector(2 downto 0);
    
        rs1    : std_logic_vector(4 downto 0);
        rs2    : std_logic_vector(4 downto 0);
        rd     : std_logic_vector(4 downto 0);
        funct3 : std_logic_vector(2 downto 0);
        funct7 : std_logic_vector(6 downto 0);
        itype  : std_logic_vector(11 downto 0);
        stype  : std_logic_vector(11 downto 0);
        btype  : std_logic_vector(12 downto 0);
        utype  : std_logic_vector(19 downto 0);
        jtype  : std_logic_vector(20 downto 0);

        csrr   : std_logic_vector(31 downto 0);
        csrren : std_logic;
    end record control_out_t;
    signal control_o : control_out_t;

    type control_in_t is record
        -- Result and program counter control
        nxtpc  : std_logic_vector(31 downto 0);
        btaken : std_logic;
        jtaken : std_logic;
        csrw   : std_logic_vector(31 downto 0);
        csrwen : std_logic;
    end record control_in_t;
    signal control_i : control_in_t;

    type memory_access_out_t is record
        -- Memory access signals
        addr    : std_logic_vector(31 downto 0);
        wdata   : std_logic_vector(31 downto 0);
        maccess : std_logic_vector(2 downto 0);
        men     : std_logic;
        mwen    : std_logic;
    end record memory_access_out_t;
    signal maccess_o : memory_access_out_t;

    type memory_access_in_t is record
        maccess : std_logic_vector(2 downto 0)
        rdata   : std_logic_vector(31 downto 0);
        rvalid  : std_logic;
    end record memory_access_in_t;
    signal maccess_i : memory_access_in_t;
begin
    
    eDataPath : DataPath
    port map (
        i_clk    => i_clk,

        -- Decoder signals
        i_pc     => control_o.pc,
        i_opcode => control_o.opcode,
        i_rs1    => control_o.rs1,
        i_rs2    => control_o.rs2,
        i_rd     => control_o.rd,
        i_funct3 => control_o.funct3,
        i_funct7 => control_o.funct7,
        i_itype  => control_o.itype,
        i_stype  => control_o.stype,
        i_btype  => control_o.btype,
        i_utype  => control_o.utype,
        i_jtype  => control_o.jtype,
        i_csrren => control_o.csrren,
        i_csrr   => control_o.csrr,

        -- Result and program counter control
        o_nxtpc  => control_i.nxtpc,
        o_btaken => control_i.btaken,
        o_jtaken => control_i.jtaken,
        o_result => control_i.result,
        o_csrwen => control_i.csrwen,
        o_csrw   => control_i.csrw,

        -- Memory access signals
        o_addr    => maccess_o.addr,
        o_wdata   => maccess_o.wdata,
        o_maccess => maccess_o.maccess,
        o_men     => maccess_o.men,
        o_mwen    => maccess_o.mwen,

        i_maccess => maccess_i.maccess,
        i_rdata   => maccess_i.rdata,
        i_rvalid  => maccess_i.rvalid
    );

    eControl : Control
    port map (
        i_clk    => i_clk,

        -- Fetch signals
        i_instr  => i_instr,
        i_valid  => i_valid,

        -- Control signals
        o_pc     => control_o.pc,
        o_opcode => control_o.opcode,
        o_rs1    => control_o.rs1,
        o_rs2    => control_o.rs2,
        o_rd     => control_o.rd,
        o_funct3 => control_o.funct3,
        o_funct7 => control_o.funct7,
        o_itype  => control_o.itype,
        o_stype  => control_o.stype,
        o_btype  => control_o.btype,
        o_utype  => control_o.utype,
        o_jtype  => control_o.jtype,

        i_nxtpc  => control_i.nxtpc,
        i_jtaken => control_i.jtaken,
        i_btaken => control_i.btaken,
        i_csrwen => control_i.csrwen,
        i_csrw   => control_i.csrw,

        -- Control I/O
        o_csrren => control_o.csrren,
        o_csrr   => control_o.csrr
    );
    
end architecture rtl;