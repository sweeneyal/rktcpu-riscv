
basic_loop.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <main>:


int main()
{
   0:	fe010113          	add	sp,sp,-32
   4:	00812e23          	sw	s0,28(sp)
   8:	02010413          	add	s0,sp,32
    int x = 0;
   c:	fe042623          	sw	zero,-20(s0)
    for (int i = 0; i < 64; i++)
  10:	fe042423          	sw	zero,-24(s0)
  14:	01c0006f          	j	30 <main+0x30>
    {
        x++;
  18:	fec42783          	lw	a5,-20(s0)
  1c:	00178793          	add	a5,a5,1
  20:	fef42623          	sw	a5,-20(s0)
    for (int i = 0; i < 64; i++)
  24:	fe842783          	lw	a5,-24(s0)
  28:	00178793          	add	a5,a5,1
  2c:	fef42423          	sw	a5,-24(s0)
  30:	fe842703          	lw	a4,-24(s0)
  34:	03f00793          	li	a5,63
  38:	fee7d0e3          	bge	a5,a4,18 <main+0x18>
    }
    return 0;
  3c:	00000793          	li	a5,0
  40:	00078513          	mv	a0,a5
  44:	01c12403          	lw	s0,28(sp)
  48:	02010113          	add	sp,sp,32
  4c:	00008067          	ret
