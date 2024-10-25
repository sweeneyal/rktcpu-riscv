from dataclasses import dataclass
from typing import Any

import numpy as np

from rktcpu.riscv.rv32i import Rv32iModel
from rktcpu.riscv.memory import Memory
from rktcpu.riscv.csr import CsrRegisters

class RktCpuModel():
    def __init__(self, settings) -> None:
        self.cpu = Rv32iModel(
            logpath=settings["logpath"],
            enablelogging=settings["enablelogging"]
        )
        self.mem = Memory(
            instr_path=settings["hexpath"], 
            instr_addr=settings["startingaddr"]
        )
        self.csr = CsrRegisters()

    def step(self) -> None:
        self.cpu.step(self.mem, self.csr)
        self.csr.step()

    def close(self) -> None:
        self.cpu.close()
