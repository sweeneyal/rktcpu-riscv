.section text
main:
    li    t0, 0
    li    t1, 0
    li    t2, 10
l1:
    bge   t0, t2, l2
    addi  t0, t0, 1
    add   t1, t1, t0
    sw    t0, 0(t0)
    j     l1
l2:
    nop