;---------------------------------------------------------------------
; The ATtiny13A blinking eyes
; Warren W. Gay VE3WWG	Fri Oct 31 19:29:08 2014
;
; This source code is licensed under the GPL v2 (see accompanying
; file LICENSE).
;
; This code is designed to drive a pair of eye LEDs for an owl on the
; wall. The eyes fade to bright and then fade away slower to dark,
; about once a minute. A 3V CR2032 battery should last about a year.
; The sleep current is about 4 uA (for ATtiny13A).
;
; While driving two LEDs, this code alternates between the two, to
; futher save power. The human eye will perceive both LEDs as being
; lit, but only one is ever on at any one instant. This also permits
; the two LEDs to share one limiting resistor.
;
; /RESET: If you flash the fuse bytes with "make finalflash", the
; reset pin is configured as an I/O port, so that the internal 
; pullup resistor can be used (saving the builder from having to
; provide an external one). The pullup resistors are disabled during
; sleep time, to reduce current draw.
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

	.section .text
	.global	main, WDT_vect

	.data
sleepc:	.byte			; Sleep count, before wakeup

;
;	Watchdog Interrupt Service Routine
;
	.text
WDT_vect:
	push	r16
	in	r16,SREG
	push	r16
	
	lds	r16,sleepc	; Get sleep counter
	cpi	r16,0
	breq	7f		; Branch if already zero
	dec	r16		; Else
	sts	sleepc,r16	;  save decremented count

7:	pop	r16
	out	SREG,r16
	pop	r16
	reti
	
;---------------------------------------------------------------------
; Reset the Watchdog Timer
;---------------------------------------------------------------------

wdreset:cli
	wdr			; Reset timer count
	in	r16,WDTCR	; Read flags in WDTCR
	ori	r16,_BV(WDCE)|_BV(WDTIE)
	out	WDTCR,r16
;
;	Have only 4 cycles to write to WDTCR now..
;	Activate Interrupt + System mode (two stage watchdog)
;
	ldi	r16,_BV(WDE)|_BV(WDTIE)|_BV(WDP3)|_BV(WDP0) ; WDT = 8 seconds
	out	WDTCR,r16
	sei			; Enable interrupts
	ret

;---------------------------------------------------------------------
; Main Program
;---------------------------------------------------------------------

	.text
main:	clr	r16
	out	DDRB,r16	; Set all ports to input
	ldi	r17,0b0111100	; PB5..PB2 have pullups on
	out	PORTB,r17	; Turn off all pullup resistors
;
	sbi	DDRB,PB1	; Left eye, output
	sbi	DDRB,PB0	; Right eye, output

	cbi	PORTB,PB1	; LED off
	cbi	PORTB,PB0	; LED off
;
	out	ADCSRA,r16	; Turn off ADC to save power
	cbi	ACSR,ACIE	; Disable Compare interrupts
	sbi	ACSR,ACD	; Turn off power to the Analog Comparator
;
	ldi	r16,_BV(SE)|_BV(SM1) ; With PUD=0 pullups enabled
	out	MCUCR,r16	; Enable Sleep Power Down
	rcall	wdreset		; Reset and start watchdog timer

;
;	Fade the eyes bright
;
mloop:	ldi	r18,1
	ldi	r19,255

1:	mov	r20,r18
	mov	r21,r19

	sbi	PINB,PB1	; Make out of step with PB0 for power savings
2:	sbi	PINB,PB1	; Toggle so only on 50%
	sbi	PINB,PB0	;  and not at the same time
	nop
	dec	r20
	brne	2b

3:	cbi	PORTB,PB1	; Turn both
	cbi	PORTB,PB0	;  LEDs off
	nop
	dec	r21
	brne	3b

	dec	r19
	inc	r18
	brne	1b
;
;	Eyes stay bright, briefly
;
	wdr
	ldi	r16,255
	sbi	PINB,PB1	; Make LEDs out of sync
4:	sbi	PINB,PB0	; Toggle LEDs so that they are not
	sbi	PINB,PB1	;  both on at the same time
	dec	r16		;   for power savings
	brne	4b
;
;	Fade the eyes dark
;
	ldi	r18,1
	ldi	r19,255
1:	mov	r20,r18
	mov	r21,r19
	
2:	cbi	PORTB,PB1
	cbi	PORTB,PB0
	nop
	nop
	nop
	nop
	nop
	dec	r20
	brne	2b

	sbi	PINB,PB0	; Make out of step with other LED
3:	sbi	PINB,PB1	; Toggle on 50%
	sbi	PINB,PB0	;  but not both on at same time
	nop
	nop
	nop
	nop
	nop
	dec	r21
	brne	3b

	dec	r19
	inc	r18
	brne	1b

	cbi	PORTB,PB1
	cbi	PORTB,PB0
;
;	Put the CPU into a deep sleep
;
	wdr
	cbi	DDRB,PB1	; Make inputs to save power
	cbi	DDRB,PB0
	ldi	r16,8		; 8 x 8 => 64 seconds of sleep time
	sts	sleepc,r16	; Initialize sleep counter
	
	in	r16,MCUCR
	ori	r16,_BV(PUD)
	out	MCUCR,r16	; Disable all pullup resistors

1:	sleep			; Go to sleep
	rcall	wdreset		; Reset watchdog timer

	lds	r16,sleepc	; Check sleep counter
	cpi	r16,0		; Zero yet?
	brne	1b		; Go back to sleep until count reaches zero

	sbi	DDRB,PB1	; Make eye ports outputs again
	sbi	DDRB,PB0

	in	r16,MCUCR
	cbr	r16,_BV(PUD)	; Enable all pullup resistors
	out	MCUCR,r16	; Disable all pullup resistors

	rjmp	mloop

;---------------------------------------------------------------------
; End eyes.S
;---------------------------------------------------------------------
