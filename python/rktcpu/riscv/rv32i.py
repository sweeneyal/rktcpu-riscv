import numpy as np

from utility import sign_extend, sll, srl, get_bits

BRANCH_OPCODE     = 0b1100011
LOAD_OPCODE       = 0b0000011
STORE_OPCODE      = 0b0100011
ALU_OPCODE        = 0b0110011
ALU_IMMED_OPCODE  = 0b0010011
JUMP_OPCODE       = 0b1101111
JUMP_REG_OPCODE   = 0b1100111
LOAD_UPPER_OPCODE = 0b0110111
AUIPC_OPCODE      = 0b0010111
FENCE_OPCODE      = 0b0001111
ECALL_OPCODE      = 0b1110011

class Rv32iModel():
    def __init__(self) -> None:
        self.pc        = np.uint32(0)
        self.registers = np.zeros([32,1], np.uint32)

    def _get_rs1(self, instr) -> int:
        return get_bits(instr, 15, 19)

    def _get_rs2(self, instr) -> int:
        return get_bits(instr, 20, 24)

    def _get_rd(self, instr) -> int:
        return get_bits(instr, 7, 11)

    def _get_opcode(self, instr) -> int:
        return get_bits(instr, 0, 6)

    def _get_funct3(self, instr) -> int:
        return get_bits(instr, 12, 14)

    def _get_funct7(self, instr) -> int:
        return get_bits(instr, 25, 31)

    def _get_itype(self, instr) -> int:
        return get_bits(instr, 20, 31)

    def _get_stype(self, instr) -> int:
        return self._get_funct7(instr) << 5 | self._get_rd(instr)

    def _get_utype(self, instr) -> int:
        return (self._get_funct7(instr) << 18) | (self._get_rs2(instr) << 8) | (self._get_rs1(instr) << 3) | self._get_funct3(instr)

    def _get_btype(self, instr) -> int:
        return (get_bits(instr, 31, 31)) << 12 | (get_bits(instr, 7, 7)) << 11 | (get_bits(instr, 25, 30)) << 5 | (get_bits(instr, 8, 11)) << 1

    def _get_jtype(self, instr) -> int:
        return (get_bits(instr, 31, 31)) << 20 | (get_bits(instr, 12, 19)) << 12 | (get_bits(instr, 20, 20)) << 11 | (get_bits(instr, 21, 30)) << 1

    def decode(self, instr) -> dict:
        decoded = dict()
        decoded["opcode"] = self._get_opcode(instr)
        decoded["rs1"]    = self._get_rs1(instr)
        decoded["rs2"]    = self._get_rs2(instr)
        decoded["rd"]     = self._get_rd(instr)
        decoded["funct3"] = self._get_funct3(instr)
        decoded["funct7"] = self._get_funct7(instr)
        decoded["itype"]  = self._get_itype(instr)
        decoded["stype"]  = self._get_stype(instr)
        decoded["utype"]  = self._get_utype(instr)
        decoded["btype"]  = self._get_btype(instr)
        decoded["jtype"]  = self._get_jtype(instr)
        return decoded
    
    def alu(self, opA, opB, funct3, funct7=None):
        if funct3 == 0:
            if funct7 == 0b0100000:
                return np.uint32(opA) - np.uint32(opB)
            else:
                return np.uint32(opA) + np.uint32(opB)
        elif funct3 == 1:
            return sll(opA, get_bits(opB, 0, 4))
        elif funct3 == 2:
            return int(np.uint32(opA) < np.uint32(opB))
        elif funct3 == 3:
            return int(np.uint32(opA) < np.uint32(opB))
        elif funct3 == 4:
            return np.uint32(opA) ^ np.uint32(opB)
        elif funct3 == 5:
            if funct7 == 0b0100000:
                return np.uint32(opA) >> np.uint32(get_bits(opB, 0, 4))
            else:
                return np.uint32(srl(opA, get_bits(opB, 0, 4)))
        elif funct3 == 6:
            return np.uint32(opA) | np.uint32(opB)
        elif funct3 == 7:
            return np.uint32(opA) & np.uint32(opB)
        
    def branch(self, opA, opB, funct3) -> bool:
        if funct3 == 0:
            return opA == opB
        elif funct3 == 1:
            return opA != opB
        elif funct3 == 4:
            return np.int32(opA) < np.int32(opB)
        elif funct3 == 5:
            return np.int32(opA) > np.int32(opB)
        elif funct3 == 6:
            return np.uint32(opA) < np.uint32(opB)
        elif funct3 == 7:
            return np.uint32(opA) > np.uint32(opB)

    def step(self, mem) -> None:
        # Get the instruction pointed to by the pc
        instr = mem.read(self.pc)
        # Decode the instruction according to the spec
        decoded  = self.decode(instr)
        # Clear the pcupdate flag
        pcupdate = False

        if decoded["opcode"] == ALU_OPCODE:
            opA = self.registers[decoded["rs1"]]
            opB = self.registers[decoded["rs2"]]
            res = self.alu(opA, opB, decoded["funct3"], decoded["funct7"])
            self.registers[decoded["rd"]] = res

        elif decoded["opcode"] == ALU_IMMED_OPCODE:
            opA = self.registers[decoded["rs1"]]
            opB = np.uint32(np.int32(sign_extend(decoded["itype"], 12)))
            if decoded["funct3"] == 1 or decoded["funct3"] == 5:
                res = self.alu(opA, opB, decoded["funct3"], decoded["funct7"])
            else:
                res = self.alu(opA, opB, decoded["funct3"])
            self.registers[decoded["rd"]] = res

        elif decoded["opcode"] == LOAD_OPCODE:
            addr = self.registers[decoded["rs1"]] + \
                np.uint32(np.int32(sign_extend(decoded["stype"], 12)))
            if decoded["funct3"] == 0:
                mode = "b"
            elif decoded["funct3"] == 1:
                mode = "h"
            elif decoded["funct3"] == 2:
                mode = "w"
            data = mem.read(addr, mode)
            self.registers[decoded["rd"]] = res

        elif decoded["opcode"] == STORE_OPCODE:
            addr = self.registers[decoded["rs1"]] + \
                np.uint32(np.int32(sign_extend(decoded["stype"], 12)))
            data = self.registers[decoded["rs2"]]
            if decoded["funct3"] == 0:
                mode = "b"
            elif decoded["funct3"] == 1:
                mode = "h"
            elif decoded["funct3"] == 2:
                mode = "w"
            mem.write(addr, data, mode)

        elif decoded["opcode"] == AUIPC_OPCODE:
            res = self.pc + (decoded["utype"] << 12)
            self.registers[decoded["rd"]] = res

        elif decoded["opcode"] == LOAD_UPPER_OPCODE:
            res = np.uint32((decoded["utype"] << 12))
            self.registers[decoded["rd"]] = res

        elif decoded["opcode"] == JUMP_OPCODE:
            self.pc = int(np.uint32(self.pc) + np.uint32(np.int32(sign_extend(decoded["jtype"], 21))))
            pcupdate = True

        elif decoded["opcode"] == JUMP_REG_OPCODE:
            self.pc = int(np.uint32(self.registers[decoded["rs1"]]) \
                          + np.uint32(np.int32(sign_extend(decoded["itype"], 12))))
            pcupdate = True

        elif decoded["opcode"] == BRANCH_OPCODE:
            opA = self.registers[decoded["rs1"]]
            opB = self.registers[decoded["rs2"]]
            if self.branch(opA, opB, decoded["funct3"]):
                self.pc = int(np.uint32(self.pc) + np.uint32(np.int32(sign_extend(decoded["btype"], 13))))
                pcupdate = True

        elif decoded["opcode"] == FENCE_OPCODE:
            print("FENCE")
        elif decoded["opcode"] == ECALL_OPCODE:
            print("ECALL")
        else:
            raise ValueError
        
        if not pcupdate:
            self.pc += 4