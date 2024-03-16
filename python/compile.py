
def compile_scurvy(scurvydir, filename):
    print('riscv32-unknown-elf-gcc -g -c -march=rv32ima {}'.format(filename))

def link_scurvy(scurvydir, libgcc):
    print('riscv32-unknown-elf-ld -o c/basic_mul/prog -T c/scrv.ld c/basic_mul/main.o /opt/riscv/lib/gcc/riscv32-unknown-elf/13.2.0/rv32im/ilp32/libgcc.a')