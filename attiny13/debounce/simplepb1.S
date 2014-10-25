;---------------------------------------------------------------------
; Simple Push Button 1 : Push Button and LED Indicator
;
; Warren W. Gay VE3WWG	Fri Oct 24 20:35:35 2014
; GPL v2 License (See file LICENSE)
;
; In this program, we configure PB2 as an output (active high)
; for the LED. When the button is pushed, the LED will be lit.
;
; GPIO PB0 is configured as input, with the pullup resistor
; enabled. When the button is pushed (connected to ground),
; PB0 will read as 0.
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

1:	bclr	6		; T=0
	sbis	PINB,PB0	; Test push button
	bset	6		; T=1 if button not pressed
	brts	2f		; Branch if T high (button unpushed)

	cbi	PORTB,PB2	; Turn LED off
	rjmp	1b

2:	sbi	PORTB,PB2	; Turn LED on
	rjmp	1b

;---------------------------------------------------------------------
; End simplepb1.S
;---------------------------------------------------------------------
