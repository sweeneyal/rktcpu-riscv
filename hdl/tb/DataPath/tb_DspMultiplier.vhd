
entity tb_DspMultiplier is
end entity tb_DspMultiplier;

architecture tb of tb_DspMultiplier is
    
begin
    
    eDut : DspMultiplier
    port map (
        i_clk    => i_clk,
        i_en     => mul_en,
        i_opA    => i_opA,
        i_opB    => i_opB,
        i_funct3 => i_funct3,
        o_result => o_mresult,
        o_done   => o_mdone
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