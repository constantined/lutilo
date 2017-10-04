.MACRO BIN2BCD3
mov	tmp1, r24
mov	tmp2, r25

ldi	r22, -1
BIN2BCD3_1:
inc	r22
subi	tmp1, byte1(100)  ; -100
sbci	tmp2, byte2(100)
brcc	BIN2BCD3_1

ldi	r25, 10
BIN2BCD3_2:
dec	r25
subi	tmp1, -10  ; +10
brcs	BIN2BCD3_2

mov	r24, tmp1
.ENDMACRO

