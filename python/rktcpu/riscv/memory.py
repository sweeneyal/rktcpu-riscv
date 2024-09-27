import numpy as np

from utility import sign_extend, sll, srl, get_bits

class Memory():
    def __init__(self, instr_path=None, instr_addr=None) -> None:
        self.memory = dict()
        if ((instr_path == None) ^ (instr_addr == None)):
            raise ValueError
        elif (instr_path != None):
            f = open(instr_path, 'r')
            for line in f:
                instr = int(line, 16)
                self.memory[instr_addr] = instr
                instr_addr += 4

    def _perform_read(self, addr, offset, mode=None):
        if mode == 'b':
            data = self.memory[addr - offset]
            data = srl(data, 8 * offset)
            data = data & 0xFF
        elif mode == 'h':
            if offset == 3:
                raise ValueError
            data = self.memory[addr - offset]
            data = srl(data, 8 * offset)
            data = data & 0xFFFF
        else: # Supports None and "w".
            if offset > 0:
                raise ValueError
            data = self.memory[addr]
        return data
    
    def read(self, addr, mode=None):
        offset = (addr % 4)
        if addr - offset in self.memory:
            return self._perform_read(addr, offset, mode)
        else:
            raise ValueError
        
    def _perform_write(self, addr, offset, data, mode=None):
        if mode == 'b':
            data = data & 0xFF
            data = sll(data, 8 * offset)
            self.memory[addr] = data
        elif mode == 'h':
            if offset == 3:
                raise ValueError
            data = data & 0xFFFF
            data = sll(data, 8 * offset)
            self.memory[addr] = data
        else: # Supports None and "w".
            if offset > 0:
                raise ValueError
            self.memory[addr] = data

    def write(self, addr, data, mode=None):
        addr = int(addr[0])
        offset = (addr % 4)
        data = np.uint32(data)
        if not (addr - offset in self.memory):
            self.memory[addr - offset] = np.uint32(0)
        self._perform_write(addr, offset, data, mode)