.global simd
simd: // void simd(unsigned char *bild, int width, int height)
/*
for optimization vectors in the 8 lanes, 8 bit format will be used when loading/saving
and vectors in 8 lanes, 16 bit format for calculations


input:
x0 image pointer
x1 width in pixels (later with in bytes to be computed)
x2 height in pixels



variables:
x3 collumn counter
x4 row counter
x5 memory offset to current pos loading
x6 memory offset to current pos storing
x7 remaining/padding loop counter
w8 center pixel/result
w9 outer pixel

d0/v0 center pixel load/save
q1/v1 center pixel calc vector
d2/v2 outer pixel load vector
q3/v3 outer pixel calc vector



constants:
x11 with in bytes of a full row (including padding zeroes)
x12 remaining elements after vector operations (width in bytes tbc mod 8)
x13 number of zeroes needed for padding
w14 -4
x15 3

q4/v4 8 lanes 16 bit, first lane containing -4
q5/v5 8 lanes 16 bit, every lane containing 255
q6/v6 custom zero register



utility:
x16/w16   temp register for calculations
q7/v7     comparison register
*/

// register init
mov x3, 0
mov x4, 0
mov x5, 0
mov x7, 0
mov x13, 0
mov w14, -4
mov v4.h[0], w14
mov x15, 3

mov w16, 255
mov v5.h[0], w16
dup v5.8h, v5.h[0]

mov w16, 0
mov v6.h[0], w16
dup v6.8h, v6.h[0]
//calculate number of padding 0
mul x1, x1, x15 //width*3 (bytes to be computed since 3 bytes per pixel)
mov x11, x1
and x16, x1, x15 // mod 4
cbz x16, .Lnomod //width*3 mod 4 == 0 which means no padding 0
mov x13, 4
sub x13, x13, x16
add x11, x11, x13 //padding 0 + with in bytes tbc = width in bytes of full row
.Lnomod:

//calculate remaining elements after vector op
and x12, x1, 7 //mod 8

// init storage counter
mul x6, x2, x11 //width of full row in bytes * height  

// start of main loop
.Lrow: //row loop
mov x3, 0	//reset collumn counter
	.Lcollumn: //collumn loop
	add x3, x3, 8		//increment collumn counter
	cmp x3, x1		//if ende of collumn for simd
	b.gt .Lremain		//branch  non-simd operations for remaining elements in collumn
	ldr d0, [x0, x5]
	uxtl v1.8h, v0.8b	//extend 8 lanes, 8 bit to 8 lanes, 16 bit format
	mul v1.8h, v1.8h, v4.h[0] //*(-4) for center pixels

	//compute up pixels
	cbz x4, .Lfirst_row 	//if first row load center pixels insted  
	sub x16, x5, x11 	// row -1
	ldr d2, [x0, x16]
	b .Lcontinue_up
	.Lfirst_row:
	ldr d2, [x0, x5] 	//center pixels
	.Lcontinue_up:
	uxtl v3.8h, v2.8b	//bit extension
	add v1.8h, v1.8h, v3.8h	//add to center pixels
	
	//compute right pixels
	add x16, x5, 3		//
	ldr d2, [x0, x16]	//load pixels to the right (+3 sinc rgb = one pixel)
	uxtl v3.8h, v2.8b	//
	cmp x3, x1		
	b.ne .Lcontinue_right	
	cbnz x12, .Lcontinue_right //if last pixels in row
	mov v3.h[7], v3.h[4]	   //		
	mov v3.h[6], v3.h[3]	   //overwrite last pixel with privious one (center pixel)
	mov v3.h[5], v3.h[2]	   //
	.Lcontinue_right:
	add v1.8h, v1.8h, v3.8h

	//compute down pixels (mostly same as up)
	sub x16, x2, 1
	cmp x4, x16
	b.eq .Llast_row		//if last row branch
	add x16, x5, x11 
	ldr d2, [x0, x16]
	b .Lcontinue_down
	.Llast_row:
	ldr d2, [x0, x5]	//and load center pixel instead
	.Lcontinue_down:
	uxtl v3.8h, v2.8b
	add v1.8h, v1.8h, v3.8h

	//compute left pixels (mostly same as right)
	sub x16, x5, 3
	ldr d2, [x0, x16]
	uxtl v3.8h, v2.8b
	cmp x3, 8
	b.ne .Lcontinue_left	//if first pixels in row
	mov v3.h[0], v3.h[3]	//
	mov v3.h[1], v3.h[4]	//overwrite first pixel with second (center pixel)
	mov v3.h[2], v3.h[5]	//
	.Lcontinue_left:
	add v1.8h, v1.8h, v3.8h

	
	cmge v7.8h, v1.8h, #0		//if results negative
	bif v1.16b, v6.16b, v7.16b	//clamp to zero
	
	cmgt v7.8h, v1.8h, v5.8h	//if results > 255
	bit v1.16b, v5.16b, v7.16b	//clamp to 255 

	xtn v0.8b, v1.8h		//shorten back to 8 lanes, 8 bit format
	str d0, [x0, x6]		//store

	add x5, x5, 8			//increment load counter
	add x6, x6, 8			//increment storage counter
	
	b .Lcollumn	




	.Lremain: //loop for remaining elements after vector op. Functionally same as simd, just one pixel each
	cmp x7, x12
	b.ge .Lremain_end	//loop logic
	ldrb w8, [x0, x5]	//load center
	mul w8, w8, w4		//*(-4) center
	
	//compute up
 	cbz x4, .Lr_first_row
	sub x16, x5, x11 
	ldrb w9, [x0, x16]
	b .Lr_continue_up
	.Lr_first_row:
	ldrb w9, [x0, x5]
	.Lr_continue_up:
	add w8, w8, w9

	//compute right
	add x16, x5, 3
	ldrb w9, [x0, x16]
	sub x16, x12, 1
	cmp x7, x16
	b.ne .Lr_continue_right	
	ldrb w9, [x0, x5]
	.Lr_continue_right:
	add w8, w8, w9
	
	//compute down
	sub x16, x2, 1
	cmp x4, x16
	b.eq .Lr_last_row
	add x16, x5, x11 
	ldrb w9, [x0, x16]
	b .Lr_continue_down
	.Lr_last_row:
	ldrb w9, [x0, x5]
	.Lr_continue_down:
	add w8, w8, w9
	
	//compute left
	sub x16, x5, 3
	ldrb w9, [x0, x16]
	cmp x3, 8
	b.ne .Lr_continue_left
	ldrb w9, [x0, x5]
	.Lr_continue_left:
	add w8, w8, w9
	
	//clamping
	cmp w8, wzr
	b.ge .Lno_zero_clamp
	mov w8, wzr
	b .Lstore
	.Lno_zero_clamp:
	
	cmp w8, 255
	b.le .Lstore
	mov w8, 255
	
	//storage + incrementing counters
	.Lstore:	
	strb w8, [x0, x6]
	add x5, x5, 1
	add x6, x6, 1
	add x7, x7, 1	

	b .Lremain
	
	
	.Lremain_end:

add x5, x5, x13 //increment load counter to compensate for padding zeroes
mov x7, x13 	//repurpose remaining loop counter for loop for adding padding zeroes

//loop for adding padding zeroes. x7(remain loop counter) ends up back at zero
.Lpadding:
cbz x7, .Lpadding_end
strb wzr, [x0, x6]
add x6, x6, 1
sub x7, x7, 1
b .Lpadding
.Lpadding_end:

add x4, x4, 1	//incrementing row counter
cmp x4, x2	//check if in last row
b.ge .Lend
b .Lrow

.Lend:
ret
