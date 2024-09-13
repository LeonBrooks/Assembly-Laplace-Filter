.global laplace
laplace:
/*
x0 image pointer
x1 width
x2 height
x3 new matrix counter
x4 up
x5 down
x6 left
x7 right
x8 middle
x9 i
x10 j
x11 counter
x12 new added 0
x13 new width
x14 tmp pointer
x15 -4
x16 3
*/

mov x15,-4
mov x16,3
//caculate the new width
mov x14,3
AND x12,x1,x14//mod 4
mov x14,4
cmp x12,xzr
b.eq .Lnomod//no need to add 0s
sub x12,x14,x12//how many 0 need to be added to achieve new width mod 4=0
.Lnomod:
add x13,x12,x1//the new width that mod 4=0
mul x13,x13,x16//3 for bgr,x13-4*x13
mul x12,x12,x16//3 for bgr

//the old width also need to *3
mul x1,x1,x16

//initiate i,j,counter
mov x9,0
mov x10,0
mov x11,0

//initiate x3 using the size
mul x3,x13,x2


.Liloop://row is the bigger loop
.Ljloop://column smaller loop
        ldrb w8,[x0,x11]//take out the center/current one
        mov x4,x8//initiate up
        mov x5,x8//initiate down
        mov x6,x8//initiate left
        mov x7,x8//initiate right
        mul x8,x8,x15//the middle one mul -4
        .Lup:
                cmp x9,xzr
                b.eq .Ldown//if i=0,use the initiate value,jump to down
                mov x14,x11//else, need to take out the one up(i-1,j)
                sub x14,x14,x13//minus new width(i-1)
                ldrb w4,[x0,x14]
        .Ldown:
                add x9,x9,1//i starts with 0,so need to add 1 to compare with height
                cmp x9,x2
                sub x9,x9,1
                b.eq .Lleft//i=height,jump to left
                mov x14,x11//(i+1,j)
                add x14,x14,x13//i+1
                ldrb w5,[x0,x14]
        .Lleft:
                cmp x10,xzr
                b.eq .Lright//if j=0,jump to right
                mov x14,x11//(i,j-1)
                sub x14,x14,3//minus one set of rgb (j-1)
                ldrb w6,[x0,x14]
        .Lright:
                add x10,x10,1//j starts with 0, compare to old width
                cmp x10,x1
                sub x10,x10,1
                b.eq .Lendd//all four directions are done
                mov x14,x11//(i,j+1)
                add x14,x14,3//j+1
                ldrb w7,[x0,x14]
        .Lendd:
        add x14,x4,x5//sum all five
        add x14,x14,x6
        add x14,x14,x7
        add x14,x14,x8
	cmp x14,xzr
	b.ge .Lover
	mov x14,0
	b .Lstore
	.Lover:
	cmp x14,255
	b.le .Lstore
	mov x14,255
	.Lstore:
        strb w14,[x0,x3]
        add x11,x11,1//the counter of the original matrix plus 1
        add x3,x3,1//the counter of the new matrix plus 1
        add x10,x10,1//j+1
        cmp x10,x1//if j<old width
        b.lt .Ljloop//jump back to next column loop
        mov x10,xzr//else j=0
        add x11,x11,x12//jump over the added 0
        add x3,x3,x12//same for the new counter
        add x9,x9,1//i+1
        cmp x9,x2//if i<height
        b.lt .Liloop//jump back to next row loop
        b .Lend//else is the matrix to the end, return
.Lend:
        ret

