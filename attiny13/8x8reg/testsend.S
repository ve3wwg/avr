;---------------------------------------------------------------------
; The ATmega328P Test Sending Program
;---------------------------------------------------------------------
;
; SOFTWARE LICENSE: GPL
;
; Use avr-gcc to compile.
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>

;---------------------------------------------------------------------
; Define Output Pin to use
;---------------------------------------------------------------------

	.list

#define TXDR	DDRB
#define	TXPORT	PORTB
; d6
#define	TXDOUT	PB0
#define TRST	PB1

	.text
	.global	main

;---------------------------------------------------------------------
; Send a zero bit
;---------------------------------------------------------------------

zero:	cbi	PORTB,PB5	; LED off
	cbi	TXPORT,TXDOUT	; Put signal low
	rcall	delay
	sbi	TXPORT,TXDOUT	; Signal = High
	sbi	PORTB,PB5	; LED on
	rcall	delay
	ret

;---------------------------------------------------------------------
; Send a one bit
;---------------------------------------------------------------------

one:	sbi	PORTB,PB5	; LED on
	sbi	TXPORT,TXDOUT	; Put signal High
	rcall	delay
	cbi	TXPORT,TXDOUT	; Signal = Low
	cbi	PORTB,PB5	; LED off
	rcall	delay
	ret

;---------------------------------------------------------------------
; Send data
;---------------------------------------------------------------------
send:	mov	r0,r16
	mov	r1,r17

	ldi	r16,12
	mov	r2,r16

	sbi	TXPORT,TXDOUT
	rcall	delay		; Settle the line high
	rcall	delay		; Settle the line high

	rcall	zero		; First 0-bit

1:	sbrc	r0,3
	rcall	one
	sbrs	r0,3
	rcall	zero

	lsl	r1
	rol	r0
	dec	r2
	brne	1b

	sbi	TXPORT,TXDOUT	; Idle line high
	ret

;---------------------------------------------------------------------
; Main Program
;---------------------------------------------------------------------

main:	sei
	ldi	r16,0b00111111	; PB5..PB0
	out	PORTB,r16	; 
	sbi	TXPORT,TXDOUT	; Signal = High
	ldi	r16,0b00111111	; PB5..PB0
	out	DDRB,r16	; Configure as outputs
	clr	r16
	sbi	TXPORT,TXDOUT	; Signal = High

;---------------------------------------------------------------------
; Send a test pattern
;---------------------------------------------------------------------

	cbi	PORTB,TRST
	rcall 	bdelay
	sbi	PORTB,TRST	; Release '13 /Reset

	rcall 	bdelay
	rcall 	bdelay

#if 1
	ldi	r16,0b00001011
	ldi	r17,0b11011101

	clr	r20
	clr	r21

1:	cpi	r20,8
	brcs	2f
	clr	r20
	inc	r21		; Skew this register by 1 more

2:	mov	r16,r20
	mov	r17,r21
	rcall	send

	inc	r21
	inc	r20
;	rcall	bdelay
	rjmp	1b
#else
3:	rcall	zero

	rcall	one
	rcall	one
	rcall	zero
	rcall	one

	rcall	one
	rcall	zero
	rcall	zero
	rcall	zero
	rcall	zero
	rcall	one
	rcall	one
	rcall	one
	sbi	TXPORT,TXDOUT	; Signal = High

	cbi	PORTB,PB5
;	rcall	bdelay
	rjmp	3b
#endif

;---------------------------------------------------------------------
; Big delay
;---------------------------------------------------------------------

bdelay:	ldi	r23,10
1:	call	mdelay
	dec	r23
	brne	1b
	ret

;---------------------------------------------------------------------
; Delay Routine
;---------------------------------------------------------------------

mdelay:	clr	r24
	clr	r25
1:	dec	r24
	brne	1b
	dec	r25
	brne	1b
	ret

delay:	ldi	r25,4
	clr	r24
1:	dec	r24
	brne	1b
	dec	r25
	brne	1b
	ret

;---------------------------------------------------------------------
; End 8x8reg.S
;---------------------------------------------------------------------
