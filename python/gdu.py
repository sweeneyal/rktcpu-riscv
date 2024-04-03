
import numpy as np

numerator = 31 * (2 ** 32 - 1)
denominator = 3 * (2 ** 32 - 1)

denominator = denominator >> 2
numerator   = numerator   >> 2

for i in range(0, 12):
    fval = 2 * (2 ** 32 - 1) - denominator
    numerator   *= fval
    denominator *= fval
    numerator    = numerator >> 32
    denominator  = denominator >> 32
    print(str(numerator) + "/" + str(denominator))

print(int(numerator/denominator))