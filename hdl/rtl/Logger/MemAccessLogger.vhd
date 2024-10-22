library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

use std.textio.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

entity MemAccessLogger is
    generic (
        cLoggerPath : string
    );
    port (
        i_clk      : in std_logic;
        i_resetn   : in std_logic;
        i_mapc     : in std_logic_vector(31 downto 0);
        i_addr     : in std_logic_vector(31 downto 0);
        i_ren      : in std_logic;
        i_wen      : in std_logic_vector(3 downto 0);
        i_wdata    : in std_logic_vector(31 downto 0);
        i_valid    : in std_logic
    );
end entity MemAccessLogger;

architecture rtl of MemAccessLogger is
    file logfile : text;
begin
    
    LoggingStructure: process(i_clk)
        variable logline : line;
        variable first   : boolean := true;
        variable cycle   : natural range 0 to 2 ** 16 - 1 := 0;
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                cycle := 0;
            else
                if (first) then
                    file_open(logfile, cLoggerPath, write_mode);
                    first := false;
                else
                    file_open(logfile, cLoggerPath, append_mode);
                end if;
                -- write(logline, 
                --     integer'image(cycle) & "," &
                --     "0x" & to_hstring(i_pc) & "," &
                --     "0x" & to_hstring(i_rd) & "," &
                --     std_logic'image(i_rdwen) & "," &
                --     "0x" & to_hstring(i_wbresult) & "," &
                --     std_logic'image(i_valid) & ",");
                writeline(logfile, logline);
                file_close(logfile);
                cycle := cycle + 1;
            end if;
        end if;
    end process LoggingStructure;
    
end architecture rtl;