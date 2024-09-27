from dataclasses import dataclass
from typing import Any

import numpy as np

from riscv.rv32i import Rv32iModel
from riscv.memory import Memory
from riscv.csr import CsrRegisters

class RktCpuModel():
    def __init__(self, settings) -> None:
        self.cpu = Rv32iModel()
        self.mem = Memory(
            instr_path=settings["ihexPath"], 
            instr_addr=settings["startingAddress"]
        )
        self.csr = CsrRegisters()

    def step(self) -> None:
        self.cpu.step(self.mem)
        self.csr.step()
