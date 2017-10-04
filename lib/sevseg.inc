.MACRO SEVSEG_INIT
	ldi	tmp1, 0xFF
	out	DDRB, tmp1
	clr	tmp1  ; optimize
	out	PORTB, tmp1
	in	tmp1, DDRD
	ori	tmp1, (1 << PD4 | 1 << PD5 | 1 << PD6)
	out	DDRD, tmp1
	in	tmp1, PORTD
	ori	tmp1, (1 << PD4 | 1 << PD5 | 1 << PD6)
	out	PORTD, tmp1
.ENDMACRO

; first digit, second, third
.MACRO SEVSEG_OUT
	ldi	zh, HIGH(SEVSEG_LOOKUP << 1)
	ldi	zl, LOW(SEVSEG_LOOKUP << 1)
	add	zl, r24
	lpm	tmp1, z
	out	PORTB, tmp1
	cbi	PORTD, PD4  ; enable first digit
	DELAY	SEVSEG_DELAY
	sbi	PORTD, PD4  ; disable first digit
	ldi	zl, LOW(SEVSEG_LOOKUP << 1)
	add	zl, r25
	lpm	tmp1, z
	out	PORTB, tmp1
	cbi	PORTD, PD5  ; enable second digit
	DELAY	SEVSEG_DELAY
	sbi	PORTD, PD5  ; disable second digit
	ldi	zl, LOW(SEVSEG_LOOKUP << 1)
	add	zl, r22
	lpm	tmp1, z
	out	PORTB, tmp1
	cbi	PORTD, PD6  ; enable third digit
	DELAY	SEVSEG_DELAY
	sbi	PORTD, PD6  ; disable third digit
.ENDMACRO

SEVSEG_LOOKUP:
.db	0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

