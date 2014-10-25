;---------------------------------------------------------------------
; Simple Push Button 2 : Button Toggles LED Indicator (no debounce)
;
; Warren W. Gay VE3WWG	Fri Oct 24 21:11:26 2014
; GPL v2 License (See file LICENSE)
;
; In this program, we configure PB2 as an output (active high)
; for the LED. When the button is pushed, the LED will be toggled
; (in theory at least, see below).
;
; GPIO PB0 is configured as input, with the pullup resistor
; enabled. When the button is pushed (connected to ground),
; PB0 will read as 0.
;
; This program will toggle the LED on and off. The problem with this
; program, is that it does not take into account "contact bounce".
; As a result, the end user will find that the toggling of the LED
; is quite irregular and unsatisfactory.
;
; Depending upon how much contact bounce there is, you may find it
; difficult, if not impossible to make the LED toggle. You might
; find for example, you can coax the LED off by holding down the
; button, only to find that the LED turns on again when you release
; the button. This is not a software bug. It is a design problem
; because this program doesn't handle bouncing button contacts.
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 		/* Avoid _SFR_IO() macro */
	.nolist
#include <avr/io.h>
	.list

	.text
	.global	main

main:	sbi	DDRB,PB2	; PB2 (LED) is output
	cbi	DDRB,PB0	; PB0 (Button) is input
	cbi	PORTB,PB2	; LED off
	sbi	PORTB,PB0	; Pullup on
	clr	r20		; r20 holds LED state

1:	bclr	6		; T=0
	sbis	PINB,PB0	; Test push button
	bset	6		; T=1 if button not pressed
	brts	1b		; Loop back, if button unpressed
;
;	Toggle the LED
;
	ldi	r16,0x01
	eor	r20,r16		; Toggle r20.0
	brne	2f		; If r20.0 set, turn on LED

	cbi	PORTB,PB2	; Turn LED off
	rjmp	1b

2:	sbi	PORTB,PB2	; Turn LED on
	rjmp	1b

;---------------------------------------------------------------------
; End simplepb1.S
;---------------------------------------------------------------------
