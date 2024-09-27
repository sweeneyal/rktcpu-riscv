import numpy as np

MSTATUS_ADDR        = 0x300
MISA_ADDR           = 0x301
MDELEG_ADDR         = 0x302
MIDELEG_ADDR        = 0x303
MIE_ADDR            = 0x304
MTVEC_ADDR          = 0x305
MENVCFG_ADDR        = 0x30A
MSTATUSH_ADDR       = 0x310
MENVCFGH_ADDR       = 0x31A
MHPMEVENT3_ADDR     = 0x323
MHPMEVENT31_ADDR    = 0x33F
MSCRATCH_ADDR       = 0x340
MEPC_ADDR           = 0x341
MCAUSE_ADDR         = 0x342
MTVAL_ADDR          = 0x343
MIP_ADDR            = 0x344
MSECCFG_ADDR        = 0x747
MSECCFGH_ADDR       = 0x757
MCYCLE_ADDR         = 0xB00
MINSTRET_ADDR       = 0xB02
MHPMCOUNTER3_ADDR   = 0xB03
MHPMCOUNTER31_ADDR  = 0xB1F
MCYCLEH_ADDR        = 0xB80
MINSTRET_ADDR       = 0xB82
MHPMCOUNTERH3_ADDR  = 0xB83
MHPMCOUNTERH31_ADDR = 0xB9F

MCSR_ADDRS = [
            MSTATUS_ADDR,
            MISA_ADDR,
            MDELEG_ADDR,
            MIDELEG_ADDR,
            MIE_ADDR,
            MTVEC_ADDR,
            MENVCFG_ADDR,
            MSTATUSH_ADDR,
            MENVCFGH_ADDR,
            MHPMEVENT3_ADDR,
            MHPMEVENT31_ADDR,
            MSCRATCH_ADDR,
            MEPC_ADDR,
            MCAUSE_ADDR,
            MTVAL_ADDR,
            MIP_ADDR,
            MSECCFG_ADDR,
            MSECCFGH_ADDR,
            MCYCLE_ADDR,
            MINSTRET_ADDR,
            MHPMCOUNTER3_ADDR,
            MHPMCOUNTER31_ADDR,
            MCYCLEH_ADDR,
            MINSTRET_ADDR,
            MHPMCOUNTERH3_ADDR,
            MHPMCOUNTERH31_ADDR
        ]

class CsrRegisters:
    def __init__(self) -> None:
        self.registers = dict()
        for addr in MCSR_ADDRS:
            self.registers[addr] = np.uint32(0)

    def _perform_read(self, addr, offset, mode=None):
        pass

    def _perform_write(self, addr, offset, data, mode=None):
        pass

    def read():
        pass

    def write():
        pass

    def step():
        pass