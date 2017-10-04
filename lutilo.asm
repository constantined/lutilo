.include "tn2313def.inc"

.equ freq = 500000
.equ sevseg_delay = freq/1000  ; show every digit 1/1000 s

.def	des_t_l = r26
.def	des_t_h = r27
.def	t_l = r18  ; temperature lower byte
.def	t_h = r19  ; temperature high byte
.def	s_t_l = r12  ; saved temperature lower byte
.def	s_t_h = r13  ; saved temperature high byte
.def	status = r28
.equ	des_t = 0
.equ	des_t_chng = 1
.equ	t_chng = 2
.def	tmp1 = r16  ; tmp1 reg
.def	tmp2 = r17  ; tmp2 reg
.def	s_sreg = r0  ; to save sreg in interrupt
.def	s_tmp1 = r1  ; to save tmp1 in interrupt

; reti  ; 1 0x0000 RESET
rjmp reset
; reti  ; 2 0x0001 INT0
rjmp int_0
; reti  ; 3 0x0002 INT1
rjmp int_1
reti  ; 4 0x0003 CAPT
; reti  ; 5 0x0004 TIMER1 COMPA
rjmp t1
reti  ; 6 0x0005 TIMER1 OVF
reti  ; 7 0x0006 TIMER0 OVF
reti  ; 8 0x0007 USART0 RX
reti  ; 9 0x0008 USART0 UDRE
reti  ; 10 0x0009 USART0 TX
reti  ; 11 0x000A ANALOG COMP
reti  ; 12 0x000B PCINT
reti  ; 13 0x000C TIMER1 COMPB
; reti  ; 14 0x000D TIMER0 COMPA
rjmp t0
; reti  ; 15 0x000E TIMER0 COMPB
; reti  ; 16 0x000F USI START
; reti  ; 17 0x0010 USI OVERFLOW
; reti  ; 18 0x0011 EE READY
; reti  ; 19 0x0012 WDT OVERFLOW


.include "delay.inc"
.include "spi.inc"
.include "bin2bcd3.inc"
.include "sevseg.inc"


int_0:
	in	s_sreg, sreg  ; save sreg
	mov	s_tmp1, tmp1
	in	tmp1, pind
	bst	tmp1, pd3
	brtc	int_dec
	adiw	des_t_h:des_t_l, (1 << 2)
	rjmp	int_timer

int_1:
	in	s_sreg, sreg  ; save sreg
	mov	s_tmp1, tmp1
	in	tmp1, pind
	bst	tmp1, pd2
	brtc	int_dec
	adiw	des_t_h:des_t_l, (1 << 2)
	rjmp	int_timer
int_dec:
	sbiw	des_t_h:des_t_l, (1 << 2)
int_timer:
	ori	status, (1 << des_t | 1 << des_t_chng)  ; show desired t (recalculate)
	clr	tmp1
	out	tcnt1h, tmp1  ; high byte must be written first to perform a true 16-bit write
	out	tcnt1l, tmp1  ; clear timer1 counter
	ldi	tmp1, (1 << wgm12 | 5)  ; wgm12 - ctc mode, 1 = no prescale, 2 = clk/8, 3 = clk/64, 4 = clk/256, 5 = clk/1024
	out	tccr1b, tmp1  ; enable timer1
	mov	tmp1, s_tmp1  ; restore tmp1
	out	sreg, s_sreg  ; restore sreg
	reti


t0:  ; thermocouple read timer interrupt
	in	s_sreg, sreg  ; save sreg
	mov	s_tmp1, tmp1
	spi_recv16 t_h, t_l, tmp1
	lsr	t_h
	ror	t_l
	lsr	t_h
	ror	t_l
	lsr	t_h
	ror	t_l

	; sub 120 grad c
;	ldi	tmp1, low(120 << 2)
;	sub	t_l, tmp1
;	ldi	tmp1, high(120 << 2)
;	sbc	t_h, tmp1

	cp	t_l, s_t_l  ; check if changed
	cpc	t_h, s_t_h
	breq	t0_end  ; not changed
	movw	s_t_h:s_t_l, t_h:t_l
	ori	status, (1 << t_chng)
	; compare des_t and t, set pd0 if need
	cp	t_l, des_t_l
	cpc	t_h, des_t_h
	brlo	t0_on
	cbi	portd, pd0
	rjmp	t0_end
t0_on:
	sbi	portd, pd0
t0_end:
	mov	tmp1, s_tmp1
	out	sreg, s_sreg
	reti

t1:
	in	s_sreg, sreg
	mov	s_tmp1, tmp1
	clr	tmp1
	out	tccr1b, tmp1
	andi	status, ~(1 << des_t)
	mov	tmp1, s_tmp1
	out	sreg, s_sreg
	reti


reset:
	; initiate stackpointer (for subroutines/interupts)
	ldi	tmp1, low(ramend)
	out	spl, tmp1 
	ldi	tmp1, high(ramend)
	out	sph, tmp1 

	sevseg_init

	; encoder
	; set pins direction
	in	tmp1, ddrd
	andi	tmp1, ~(1 << pd2 | 1 << pd3)
	out	ddrd, tmp1
	; enable pull-ups
	in	tmp1, portd
	ori	tmp1, (1 << pd2 | 1 << pd3)
	out	portd, tmp1
	; int0 - falling edge, int1 - raising edge
	ldi	tmp1, (1 << isc01 | 1 << isc11 | 1 << isc10)
	out	mcucr, tmp1
	; enable int0 and int1
	in	tmp1, gimsk
	ori	tmp1, (1 << int0 | 1 << int1)
	out	gimsk, tmp1

	; timer 0
	ldi	tmp1, (1 << wgm01)  ; wgm01 - ctc mode
	out	tccr0a, tmp1
	ldi	tmp1, 5  ; 1 = no prescale, 2 = clk/8, 3 = clk/64, 4 = clk/256, 5 = clk/1024
	out	tccr0b, tmp1
	ldi	tmp1, 122  ; (1/(500000 Hz/1024/122)) ~ 0.25 s (220 ms - max conv time)
	out	ocr0a, tmp1
	; timer 1
	ldi	tmp1, high(733)  ; (high first) (1/(500000 Hz/1024/733)) ~ 1.5 s
	out	ocr1ah, tmp1
	ldi	tmp1, low(733)  ; (1/(500000 Hz/1024/733)) ~ 1.5 s
	out	ocr1al, tmp1
	; enable timer interrupts
	in	tmp1, timsk
	ori	tmp1, (1 << ocie0a | 1 << ocie1a)
	out	timsk, tmp1

	spi_init

	; control pin
	sbi	ddrd, pd0

	ldi	des_t_l, low(280 << 2)
	ldi	des_t_h, high(280 << 2)

	sei  ; enable interrupts

mainloop:
	bst	status, des_t
	brtc	mainloop_no_des
	bst	status, des_t_chng
	brtc	mainloop_out  ; skip calculations if des_t not changed
	movw	r25:r24, des_t_h:des_t_l
	rjmp	mainloop_common
mainloop_no_des:
	delay	(sevseg_delay * 3 * 2)
	bst	status, t_chng
	brtc	mainloop_out  ; skip calculations if t not changed
	movw	r25:r24, t_h:t_l
mainloop_common:
	lsr	r25
	ror	r24
	lsr	r25
	ror	r24
	bin2bcd3
mainloop_out:
	sevseg_out
	rjmp	mainloop


