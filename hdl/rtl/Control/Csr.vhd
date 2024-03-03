library ieee;
    use ieee.numeric_std.all;
    use ieee.std_logic_1164.all;

library scrv;
    use scrv.CsrDefinitions.all;

entity Csr is
    generic (
        cFloatExtension : boolean
    );
    port (
        i_clk     : in std_logic;

        i_csraddr : in std_logic_vector(11 downto 0);
        i_priv    : in std_logic_vector(2 downto 0);
        i_wdata   : in std_logic_vector(31 downto 0);
        i_wen     : in std_logic;
        i_ren     : in std_logic;
        o_rdata   : out std_logic_vector(31 downto 0);

        o_afault : out std_logic
    );
end entity Csr;

architecture rtl of Csr is
    signal scsr : supervisor_csr_t;
    signal mcsr : machine_csr_t;
begin
    
    CsrControl: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_ren = '1' or i_wen = '1') then
                handle_accesses(
                    i_priv  => i_priv,
                    i_addr  => i_csraddr,
                    i_wen   => i_wen,
                    i_ren   => i_ren,
                    i_wdata => i_wdata,
                    i_scsr  => scsr,
                    i_mcsr  => mcsr,
                    o_rdata => o_rdata,
                    o_fault => o_afault
                );
            else
                -- manage counters, interrupts, and statuses here
            end if;
        end if;
    end process CsrControl;
    
    
end architecture rtl;