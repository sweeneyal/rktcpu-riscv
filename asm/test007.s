.section text
main:
    la    t0, var
    li    t1, 0
    addi  t2, t0, 32
loop0:
    sw    t1, 0(t0)
    addi  t0, t0, 4
    addi  t1, t1, 1
    blt   t0, t2, loop0
    la    t0, var
loop:
    lw    t1, 0(t0)
    add   t1, t1, t1
    sw    t1, 0(t0)
    addi  t0, t0, 4
    blt   t0, t2, loop
    j main
    nop
    nop
    nop
    nop
    nop
    nop
    
.data
var: 
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    