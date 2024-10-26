.section text
main:
    li    t0, 0
    li    t1, 0
    li    t2, 10
    la    t3, var
l1:
    bge   t0, t2, l2
    addi  t0, t0, 1
    add   t1, t1, t0
    sw    t0, 0(t3)
    j     l1
l2:
    j     main
    nop
    nop
    nop
    nop
    nop


.data
var:
    .word 0