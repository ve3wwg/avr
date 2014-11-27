;---------------------------------------------------------------------
; ATtiny13 Manchester Send Program: Module test13.S
; Wed Nov 26 19:26:40 2014  Warren Gay VE3WWG
;
; This is a test program for the ATtiny13 in assembler. See also the
; companion program testmain.c
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

	.text
	.global init8x8, tx8x8
	.global	main

	.data

byte:	.byte	0x01
up:	.byte	1
intens:	.byte	1

;---------------------------------------------------------------------
; Main program (assembler version of testmain.c for ATtiny13)
;---------------------------------------------------------------------

	.text
main:	cli
	ldi	r16,0b10000000
	ldi	r17,0b00000000	; Select "full speed" for ATtiny13
	out	CLKPR,r16	; Start clock prescale change
	out	CLKPR,r17	; Set clock prescale
	sei

	rcall	init8x8		; Initialize for sending to matrix

	ldi	r16,1
	sts	byte,r16
	sts	up,r16
	sts	intens,r16

loop:	clr	r2
1:	mov	r24,r2		; Digit: 0-7
	lds	r22,byte	; Value
	rcall	tx8x8		; Display it on matrix

	inc	r2		; Next digit
	mov	r24,r2		; Save it
	cpi	r24,8		; < 8 ?
	brcs	1b		; Loop until 8

	lds	r22,byte
	inc	r22		
	sts	byte,r22	; ++byte

	lds	r16,up
	lds	r22,intens	; Arg 2
	tst	r16		; if ( up )
	breq	2f		; Jump if !up

	inc	r22
	cpi	r22,15
	brcc	3f		; Jump if ( ++intens <= 15 )
	sts	intens,r22	; ++intens

	ldi	r24,8		; Arg 1
	rcall	tx8x8		; Display
	rjmp	loop

3:	clr	r22
	sts	up,r22		; up = 0
	rjmp	loop

2:	dec	r22
	sts	intens,r22	; --intens
	brne	4f		; jump if !--intense

	ldi	r22,1		
	sts	up,r22		; up = 1
	rjmp	loop

4:	ldi	r24,8		; Arg 1 = 8
	lds	r22,intens	; Arg 2 = intens
	rcall	tx8x8
	rjmp	loop

;---------------------------------------------------------------------
; End test13.S
;---------------------------------------------------------------------
