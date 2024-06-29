.section text
.global arraysum
arraysum:
    # a0 = int a[]
    # a1 = int size
    # t0 = ret
    # t1 = i
    li   t0, 0
    li   t1, 0
l1:
    bge  t1, a1, l2
    slli t2, t1, 2
    add  t2, a0, t2
    lw   t2, 0(t2)
    add  t0, t0, t2
    addi t1, t1, 1
    j    l1
l2:
    mv   a0, t0
    ret