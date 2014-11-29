;---------------------------------------------------------------------
; ATtiny13 Manchester Send Program: Module test13.S
; Wed Nov 26 19:26:40 2014  Warren Gay VE3WWG
;
; This is a test program for the ATtiny13 in assembler. See also the
; companion program testmain.c
;
; This program is intented to run on an ATtiny13. At startup, the 
; code sets the CPU clock frequency to 8 MHz (so assemble F_CPU
; as 8 MHz for accurate timing).
;
; This program generates a sequence of byte patterns to be displayed
; on the matrix. The biphase manchester code is transmitted from 
; port PB0 (unless tx8x8.S has been altered).
;
; PB4 is configured as an input for a push button (optional). When
; button is pressed, the matrix is cleared and the current byte
; value and it's 1's complement are displayed on rows 2 and 4.
; When the button is released, the sequence is restarted.
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

	.text
	.global init8x8, tx8x8
	.global	main

;---------------------------------------------------------------------
; SRAM Area
;---------------------------------------------------------------------

	.data
byte:	.byte	0x01		; The current byte pattern to be displayed
up:	.byte	1		; Intensity rises, when != 0
intens:	.byte	1		; Matrix LED Intensity from 1 to 15

;---------------------------------------------------------------------
; This code is executed when the Push Button (PB4) is pushed (grounded)
;---------------------------------------------------------------------
	.text
pbpushed:
	clr	r2		; Digit = 0

1:	mov	r24,r2		; Arg 1 = digit
	clr	r22		; Arg 2 = 0x00
	rcall	tx8x8		; Clear matrix row

	inc	r2		; Next digit
	mov	r16,r2
	cpi	r16,8		; Until digit = 8
	brne	1b

	ldi	r24,2		; Display byte on row 2
	lds	r22,byte
	rcall	tx8x8		; Display it

	lds	r22,byte
	com	r22		; Invert the bits
	ldi	r24,4
	rcall	tx8x8		; Display that on row 4

2:	sbis	PINB,PB4	; Test if button still down
	rjmp	2b		;  Loop until button released
	rjmp	9f		; Else restart at 9f when released

;---------------------------------------------------------------------
; Main program (assembler version of testmain.c for ATtiny13)
;---------------------------------------------------------------------

main:	cli
	ldi	r16,0b10000000	; Changing the CPU clock prescaler
	ldi	r17,0b00000000	; Select "full speed" for ATtiny13
	out	CLKPR,r16	; Start clock prescale change
	out	CLKPR,r17	; Set clock prescale
	sei

	rcall	init8x8		; Initialize for sending to matrix (PB0 out)

	cbi	DDRB,PB4	; Configure PB4 as push button input
	sbi	PINB,PB4	; Enable pull-up resistor

9:	ldi	r16,1		
	sts	byte,r16	; byte = 1
	sts	up,r16		; up = 1
	sts	intens,r16	; intens = 1

loop:	clr	r2		; digit = 0
1:	mov	r24,r2		; Arg 1, digit: 0-7
	lds	r22,byte	; Arg 2, Value to be displayed
	rcall	tx8x8		; Send it for display on matrix

	inc	r2		; ++digit

	lds	r22,byte
	inc	r22		
	sts	byte,r22	; ++byte

	sbis	PINB,PB4	; Test if push button down (grounded)
	rjmp	pbpushed	; This is skipped if not button down

	mov	r24,r2		; if digit..
	cpi	r24,8		;   < 8 ?
	brcs	1b		; Yes, then loop

	inc	r22
	sts	byte,r22	; ++byte once more for visual effect

	lds	r16,up
	lds	r22,intens	; Arg 2 = intens
	tst	r16
	breq	2f		; if ( !up ) then 2f

	inc	r22		; increase intensity
	cpi	r22,15		; compare to 15
	brcc	3f		; if ( ++intens > 15 ) then 3f
	sts	intens,r22	; ++intens (saved)

	ldi	r24,8		; Arg 1 (digit = 8)
	rcall	tx8x8		; Set display intensity (r22)
	rjmp	loop

3:	clr	r22		; Set
	sts	up,r22		;   up = 0
	rjmp	loop

2:	dec	r22
	sts	intens,r22	; --intens
	brne	4f		; if ( instens != 0 ) then 4f

	ldi	r22,1		; Set
	sts	up,r22		;   up = 1
	rjmp	loop

4:	ldi	r24,8		; Arg 1 = 8
	lds	r22,intens	; Arg 2 = intens
	rcall	tx8x8		; Display decreasing intensity
	rjmp	loop

;---------------------------------------------------------------------
; End test13.S
;---------------------------------------------------------------------
