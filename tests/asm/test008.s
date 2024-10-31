.section text
main:
    li    a0, 75000000
    li    t0, 0
    li    t1, 0
    la    t2, var
loop0:
    addi  t0, t0, 1
    blt   t0, a0, loop0
    xori  t1, t1, 1
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