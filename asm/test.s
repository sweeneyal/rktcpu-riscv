.section text
main:
    li t1, 100
    li t2, 200
    add t3, t1, t2
    sub t4, t2, t1
    la t2, num0
    sw t4, 0(t2)
    la t2, num1
    sh t4, 0(t2)
    la t2, num2
    sb t4, 0(t2)
    lb a5, 0(t2)
    la t2, num1
    lh a5, 0(t2)
    la t2, num0
    lw a5, 0(t2)
    slt a6, t1, t2
    nop
    nop
    nop
    nop
    nop
    
.data
num0:
    .word 0
num1:
    .half 0
num2:
    .byte 0