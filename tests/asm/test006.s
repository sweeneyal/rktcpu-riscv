.section text
main:
    li    a0, 25
    li    t3, 0
    li    t4, 14
loop:
    addi  t3, t3, 1
    jal   ra, sqrt
    blt   t3, t4, loop
    j main
    nop
    nop
    nop
    nop
    nop
    nop
sqrt:
    li    t0, 0
    li    t1, -1
    mv    t2, a0
wloop:
    addi  t1, t1, 2
    addi  t0, t0, 1
    sub   t2, t2, t1
    bne   t2, zero, wloop
    ret
    nop
    nop
    nop
    nop
    nop