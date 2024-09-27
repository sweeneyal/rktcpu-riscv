import numpy as np

def sign_extend(value, bits):
    sign_bit = 1 << (bits - 1)
    return (value & (sign_bit - 1)) - (value & sign_bit)

def sll(val, n):
    return (val << n) & (1 << np.iinfo(type(val)).bits - 1)

def srl(val, n): 
    return (val % 0x100000000) >> n

def mask(lhs, rhs):
    m = 0x0
    for i in range(32):
        if i >= lhs and i <= rhs:
            m |= (1 << i)
    return m

def get_bits(val, lhs, rhs):
    m = mask(lhs, rhs)
    return srl(val & m, lhs) 