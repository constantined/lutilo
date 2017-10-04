.MACRO DELAY
	movw	tmp2:tmp1, ZH:ZL  ; 1 cycle
	ldi	ZL, LOW( ( @0 - 3 ) / 4 )  ; 1 cycle
	ldi	ZH, HIGH( ( @0 - 3 ) / 4 )  ; 1 cycle
DELAY_LOOP:
	sbiw	ZH:ZL, 1  ; 2 cycles
	brne	DELAY_LOOP  ; 2 cycles, 1 cycle last
	movw	ZH:ZL, tmp2:tmp1  ; 1 cycle
.ENDMACRO

