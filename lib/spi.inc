.macro spi_init
	sbi	PORTA, PA0  ; set chip select to high
	cbi	PORTA, PA1  ; set clock to low
	in	tmp1, DDRA
	ori	tmp1, (1 << PA0 | 1 << PA1)
	out	DDRA, tmp1
	sbi	PORTD, PD1  ; pull up miso
	in	tmp1, DDRD
	andi	tmp1, ~(1 << PD1)  ; use this pin for input (miso)
	out	DDRD, tmp1
.endmac


.macro spi_recv16  ; @0 - h, @1 - l, @2 - tmp
	clr	@0
	clr	@1
	cbi	PORTA, PA0  ; set chip select to low state
	ldi	@2, 8
spi_recv16_h:
	lsl	@0
	sbi	PORTA, PA1  ; set clock to high state
	sbic	PIND, PD1  ; check miso state
	ori	@0, 1
	cbi	PORTA, PA1  ; set clock to low state
	dec	@2
	brne	spi_recv16_h
	ldi	@2, 8
spi_recv16_l:
	lsl	@1
	sbi	PORTA, PA1  ; set clock to high state
	sbic	PIND, PD1  ; check miso state
	ori	@1, 1
	cbi	PORTA, PA1  ; set clock to low state
	dec	@2
	brne	SPI_RECV16_L
	sbi	PORTA, PA0  ; set chip select to high
.endmac

