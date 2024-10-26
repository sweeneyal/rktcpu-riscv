.section text
main:
    li    a0, 100000000
    li    t0, 16
    li    t1, 0
    la    t2, var
    li    t3, 0
loop0:
    addi  t3, t3, 1
    blt   t3, a0, loop0
    addi  t1, t1, 1
    sw    t1, 0(t2)
    j loop
    nop
    nop
    nop
    nop
    nop
    nop

.data
var: 
    .word 0