.section text
main:
    li    t0, 0
    li    t1, 0
    li    t2, 0
    li    t3, 0
    li    t4, 20
loop:
    addi  t3, t3, 1
    addi  t0, t0, 100
    addi  t1, t1, 100
    addi  t2, t2, 100
    addi  t0, t0, 100
    addi  t1, t1, 100
    addi  t2, t2, 100
    addi  t0, t0, 100
    addi  t1, t1, 100
    addi  t2, t2, 100
    blt   t3, t4, loop
    j main
    nop
    nop
    nop
    nop
    nop
    nop