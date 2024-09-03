from dataclasses import dataclass
from typing import Any

import numpy as np

def sign_extend(value, bits):
    sign_bit = 1 << (bits - 1)
    return (value & (sign_bit - 1)) - (value & sign_bit)

def srl(val, n): 
    return (val % 0x100000000) >> n

@dataclass
class Pipeline:
    pc     : int
    opcode : int
    rs1    : int
    rs2    : int
    rd     : int
    funct3 : int
    funct7 : int
    itype  : int
    stype  : int
    btype  : int
    utype  : int
    jtype  : int
    valid  : bool

    def __post_init__(self):
        self.__extents = {
            "pc"     : (0, 2 ** 32 - 1),
            "opcode" : (0, 2 ** 7 - 1),
            "rs1"    : (0, 31),
            "rs2"    : (0, 31),
            "rd"     : (0, 31),
            "funct3" : (0, 7),
            "funct7" : (0, 2 ** 7 - 1),
            "itype"  : (0, 2 ** 12 - 1),
            "stype"  : (0, 2 ** 12 - 1),
            "btype"  : (0, 2 ** 13 - 1),
            "utype"  : (0, 2 ** 20 - 1),
            "jtype"  : (0, 2 ** 21 - 1)
        }

    def __setattr__(self, name: str, value: Any) -> None:
        if self.__extents[name][0] <= value and self.__extents[name][0] >= value:
            self.__dict__[name] = value
        else:
            raise ValueError
        
class Alu:
    def __init__(self) -> None:
        self.operand_a = 0
        self.operand_b = 0
        self.result    = 0
    
    def __setattr__(self, name: str, value: Any) -> None:
        if -(2 ** 32) <= value and (2 ** 33) - 1 >= value:
            self.__dict__[name] = value
        elif -(2 ** 32) > value:
            self.__dict__[name] = value

    def step(self, opcode, funct3, funct7) -> None:
        if funct3 == 0b000:
            if opcode == 0b0110011:
                if funct7 == 0b0100000:
                    self.result = self.operand_a - self.operand_b
                else:
                    self.result = self.operand_a + self.operand_b
            elif opcode == 0b0010011:
                self.result = self.operand_a + self.operand_b
        elif funct3 == 0b001:
            self.result = (self.operand_a << abs(self.operand_b)) % (2 ** 32)
        elif funct3 == 0b010:
            self.result = int(self.operand_a < self.operand_b)
        elif funct3 == 0b011:
            self.result = int(abs(self.operand_a) < abs(self.operand_b))
        elif funct3 == 0b100:
            self.result = (self.operand_a and not self.operand_b) \
                or (not self.operand_a and self.operand_b) 
        elif funct3 == 0b101:
            if funct7 == 0b0100000:
                self.result = srl(self.operand_a, self.operand_b)
            else:
                self.result = self.operand_a >> self.operand_b
        elif funct3 == 0b110:
            self.result = self.operand_a or self.operand_b
        elif funct3 == 0b111:
            self.result = self.operand_a and self.operand_b
        else:
            raise ValueError

class Memory:
    def __init__(self) -> None:
        self.addresses = list()
        self.memory    = list()

        self.address = 0
        self.wdata   = 0
        self.size    = 0
        self.rdata   = 0

    def step(self) -> None:
        pass

    def load(self, address, size) -> int:
        pass

    def store(self, address, wdata, size) -> None:
        pass

class FlowControl:
    def __init__(self) -> None:
        pass

    def step(self) -> None:
        pass
        
class Csr:
    def __init__(self) -> None:
        pass

    def step(self) -> None:
        pass

class RktCpuModel:
    def __init__(self, executable=None) -> None:
        # Administrative stuff for the whole simulation
        self.executable = executable
        self.done       = False

        # Hardware models
        self.pipeline   = [Pipeline() for _ in range(4)]
        self.registers  = [0 for _ in range(32)]
        self.alu        = Alu()
        self.memory     = Memory()
        self.flow       = FlowControl()
        self.csr        = Csr()

        # Additional supporting registers
        self.pc         = 0
        self.instr      = 0
        self.cycle      = 0

    def step(self) -> None:
        # Identify hazard relationships between pipelines
        hazards = self.identify_hazards()

        # Reassign signals based on hazards, pipeline, etc.
        expl       = self.pipeline[1]
        operand_a  = self.registers[expl.rs1]
        operand_b  = self.registers[expl.rs2]

        if expl.opcode == 0b0010011:
            operand_b = sign_extend(expl.itype, 12)

        self.alu.operand_a = operand_a
        self.alu.operand_b = operand_b

        # Run each hardware model with their updated arguments
        self.alu.step(expl.opcode, expl.funct3, expl.funct7)
        self.memory.step()
        self.flow.step()
        self.csr.step()

        # Move the pipeline along at the end to make it available
        # for the next step.
        for i in range(0, 3):
            self.pipeline[i + 1] = self.pipeline[i]
        self.pipeline[0] = self.decode(self.instr)
        self.instr = self.executable[int(self.pc / 4)]
        self.pc    += 4

    def run(self, cyclelimit, executable=None) -> None:
        while self.done == False or self.cycle < cyclelimit:
            self.step()
            self.cycle += 1

    def decode(self, instruction) -> Pipeline:
        pass

    def identify_hazards(self) -> list:
        rs1s = [self.pipeline[i].rs1 for i in range(4)]
        rs2s = [self.pipeline[i].rs1 for i in range(4)]
        rds  = [self.pipeline[i].rd for i in range(4)]

        # For each combination of the destination registers,
        # check if the destination register of a more-completed
        # instruction is a source register of a later instruction.
        # This also requires checking if the register fields
        # really matter, because certain register fields are 
        # unused.

        map_rs1 = [[False for _ in range(4)] for __ in range(4)]
        for i_stage in range(4):
            for j_stage in range(4):
                map_rs1(i_stage)(j_stage) = \
                    (rs1s(i_stage) == rds(j_stage)) and j_stage > i_stage
                # Check to see if rs1 and rd are both valid signals. This means
                # checking if the instruction meets certain criteria.

        map_rs2 = [[False for _ in range(4)] for __ in range(4)]
        for i_stage in range(4):
            for j_stage in range(4):
                map_rs2(i_stage)(j_stage) = \
                    rs2s(i_stage) == rds(j_stage) and j_stage > i_stage