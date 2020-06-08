#define __SFR_OFFSET 0 
#include <avr/io.h>

	.section .text
	.equ	sreg,63
	.equ	IO_Base,0x0020
;
;	Interrupt Vector
;
	rjmp	test26
	rjmp	ext_int0
	rjmp	pcint0
	rjmp	tim0_ovf
	rjmp	ee_rdy
	rjmp	ana_comp
	rjmp	tim0_compa
	rjmp	tim0_compb
	rjmp	watchdog
	rjmp	adc
;
;	LDS
;
test26: eor     0,0
        eor     1,1
        inc     1
	lds	21,0
	lds	22,1
	cpi	21,0
	breq	2f
	break		; Fail
2:	cpi	22,1
	breq	2f
	break		; Fail
2:
;
;	LPM
;
test27:	ldi	30,pm_lo8(tword)
	ldi	31,pm_hi8(tword)
tword:	lpm	16,Z
	cpi	16,0x04
	breq	2f
	break		; Fail
2:	lpm		; -> r0
	mov	16,0
	cpi	16,0x04
	breq	2f
	break		; Fail
2:	lpm	17,Z+
	cpi	17,0x04
	breq	2f
	break		; Fail
2:	lpm	18,Z+
	cpi	18,0x91
	breq	2f
	break		; Fail
2:
;
;	LSL
;
test28:	ldi	16,0x53
	mov	0,16
	mov	1,16
	lsl	16
	cpi	16,0xA6
	breq	2f
	break		; Fail
2:	lsl	0
	mov	17,0
	cpi	17,0xA6
	breq	2f
	break		; Fail
2:	mov	18,1
	lsl	18
	brcc	2f
	break		; Fail
2:	lsl	18
	brcs	2f
	break		; Fail
2:	cpi	18,0x4C
	breq	2f
	break		; Fail
2:
;
;	LSR
;
test29:	ldi	19,0xF5
	lsr	19
	brcs	2f
	break		; Fail
2:	cpi	19,0x7A
	breq	2f
	break		; Fail
2:	lsr	19
	lsr	19
	lsr	19
	lsr	19
	lsr	19
	lsr	19
	lsr	19
	breq	2f
	break		; Fail
2:
end:	break
	rjmp	end

ext_int0:
pcint0:
tim0_ovf:
ee_rdy:
ana_comp:
tim0_compa:
tim0_compb:
watchdog:
adc:
	rjmp	ext_int0

