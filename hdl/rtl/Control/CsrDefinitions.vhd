

package CsrDefinitions is
    
    type machine_csr_t is record
        misa      : std_logic_vector(31 downto 0);
        mvendorid : std_logic_vector(31 downto 0);
        marchid   : std_logic_vector(31 downto 0);
        mimpid    : std_logic_vector(31 downto 0);
        mhartid   : std_logic_vector(31 downto 0);
        mstatus   : std_logic_vector(31 downto 0);
        mstatush  : std_logic_vector(31 downto 0);
        mtvec     : std_logic_vector(31 downto 0);
        medeleg   : std_logic_vector(31 downto 0);
        mideleg   : std_logic_vector(31 downto 0);
        mip       : std_logic_vector(31 downto 0);
        mie       : std_logic_vector(31 downto 0);

        mcycle        : u64_t;
        minstret      : u64_t;
        mhpmcounters  : u64_array_t(3 to 31);
        mhpmevents    : std_logic_matrix_t(3 to 31)(31 downto 0);
        mcounteren    : std_logic_vector(31 downto 0);
        mcountinhibit : std_logic_vector(31 downto 0);
        
        mscratch      : std_logic_vector(31 downto 0);
        mepc          : std_logic_vector(31 downto 0);
        mcause        : std_logic_vector(31 downto 0);
        mtval         : std_logic_vector(31 downto 0);
        mconfigptr    : std_logic_vector(31 downto 0);
        menvcfg       : std_logic_vector(63 downto 0);
        mseccfg       : std_logic_vector(63 downto 0);

        mtime         : std_logic_vector(63 downto 0);
        mtimecmp      : std_logic_vector(63 downto 0);
    end record machine_csr_t;

    type supervisor_csr_t is record
        sstatus : std_logic_vector(31 downto 0);
        stvec   : std_logic_vector(31 downto 0);
        sip     : std_logic_vector(31 downto 0);
        sie     : std_logic_vector(31 downto 0);

        scounteren : std_logic_vector(31 downto 0);
        sscratch   : std_logic_vector(31 downto 0);
        sepc       : std_logic_vector(31 downto 0);
        scause     : std_logic_vector(31 downto 0);
        stval      : std_logic_vector(31 downto 0);
        senvcfg    : std_logic_vector(31 downto 0);

        satp : std_logic_vector(31 downto 0);
    end record supervisor_csr_t;

    type user_csr_t is record
        
    end record user_csr_t;
    
end package CsrDefinitions;