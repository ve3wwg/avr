;---------------------------------------------------------------------
; Manchester Send Subroutine: Module tx8x8.S
;
; void tx8x8(uint8_t digit,uint8_t byte)
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

;---------------------------------------------------------------------
; Configure These
;---------------------------------------------------------------------

DDRX	= DDRB
PORTX	= PORTB
PBX	= PB0

	.text
	.global	tx8x8,init8x8

;---------------------------------------------------------------------
; Send a zero bit
;---------------------------------------------------------------------

zero:	cbi	PORTX,PBX	; Signal = low
	rcall	txdelay
	sbi	PORTX,PBX	; Signal = High
	rcall	txdelay
	ret

;---------------------------------------------------------------------
; Send a one bit
;---------------------------------------------------------------------

one:	sbi	PORTX,PBX	; Put signal High
	rcall	txdelay
	cbi	PORTX,PBX	; Signal = Low
	rcall	txdelay
	ret

;---------------------------------------------------------------------
; Initialize for output 
;
; void init8x8();
;---------------------------------------------------------------------
init8x8: sbi	DDRX,PBX	; Set pin as output
	sbi	PORTX,PBX	; Set line idle high

	sbi	DDRX,PB1
	cbi	PORTX,PB1	; Apply /RESET
	nop
	sbi	PORTX,PB1	; Release /Reset

	sbi	DDRX,PB5	; LED
	sbi	PORTX,PB5

	ldi	r20,255
1:	rcall	txdelay
	dec	r20
	brne	1b

	cbi	PORTX,PB5

	ret

;---------------------------------------------------------------------
; Send data in r16 (arg1) for digit in r17 (arg2)
;
; void tx8x8(uint8_t digit,uint8_t byte)
; Registers:
;	digit	r24
;	byte	r22
;---------------------------------------------------------------------

tx8x8:	rcall	txdelay		; Delay one complete
	rcall	txdelay		;   bit cell
	rcall	zero		; Start with a zero bit

	ldi	r19,12		; 4 + 8 bits

1:	sbrc	r24,3		; Skip if msb of digit is clear
	rcall	one		;  else emit a 1-bit
	sbrs	r24,3		; Skip if msb of digit is set
	rcall	zero		;  else emit a 0-bit

	lsl	r22		; Shift the byte value left 1 bit
	rol	r24		; Shift the digit value left and include byte bit
	dec	r19		; One more bit sent
	brne	1b		; Loop until all bits sent

	sbi	PORTX,PBX	; Idle line high
	ret

;---------------------------------------------------------------------
; Delay approx 645+ us (depends upon calculated NITER)
;---------------------------------------------------------------------

txdelay: ldi	r18,(F_CPU/4000000)%256	; How many times to iterate?
2:	clr	r17		; Zero for maximum time wastage
1:	dec	r17		; Iterate for 256 x 2 cycles
	brne	1b
	dec	r18		; Decrement NITER
	brne	1b		; Until we hit zero
	ret

;---------------------------------------------------------------------
; End tx8x8.S
;---------------------------------------------------------------------
