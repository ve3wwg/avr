;---------------------------------------------------------------------
; Blink assert macro for ATtiny debugging.
; Thu Oct 23 20:56:05 2014	Warren W. Gay VE3WWG
; License: GPL v2 (see accompanying file LICENSE)
; See end of this file for more info.
;---------------------------------------------------------------------

#ifndef F_CPU
#warning "F_CPU is not defined: 8000000 assumed."
#define F_CPU	8000000
#endif

;---------------------------------------------------------------------
; Initialize for bassert LED operation
;
; Macro parameters:
;	Param	Default	Description
;	ddrx	DDRB	Data direction register for GPIO
;	portx	PORTB	GPIO port for LED
;	bit	PB5	Port B bit 5 (LED)
;
; This module assumes that the LED is lit when GPIO is active high.
;---------------------------------------------------------------------

.macro	bassert_init ddrx=DDRB, portx=PORTB, bit=PB5
#ifndef NDEBUG
#if _SFR_ASM_COMPAT == 0
	sbi	\ddrx,\bit	; Enable this GPIO as output
	cbi	\portx,\bit	; Initialize LED as off (low, active high)
#else
	sbi	_SFR_IO_ADDR(\ddrx),\bit  ; Enable this GPIO as output
	cbi	_SFR_IO_ADDR(\portx),\bit ; Initialize LED as off (low, active high)
#endif
	rjmp	79076f
;
;	delay n ticks, where each tick is about 32 ms
;
;	r16+r17	input: ticks
;	Clobbers r0, r1, r16, r17
;
delay:	clr	r0
	clr	r1
79075:	dec	r0
	brne	79075b
	dec	r1
	brne	79075b
	subi	r16,1
	sbci	r17,0
	brne	79075b
	ret
;
;	Compute relative timings based upon F_CPU
;
__79077 = ( 256 * 256 * 4 * 1000 ) / F_CPU	; Time of inner loop (usec)
__79087 = 800 / __79077				; Ticks for LED on
__79088 = 700 / __79077				; Ticks for LED off
__79089 = 2400 / __79077			; Ticks for pause
;
;	Blink n times, pause and repeat forever
;
blinkn:	mov	r19,r16
79075:	mov	r18,r19
79078:
#if _SFR_ASM_COMPAT == 0
	sbi	\portx,\bit
#else
	sbi	_SFR_IO_ADDR(\portx),\bit
#endif
	ldi	r16,lo8(__79087)
	ldi	r17,hi8(__79087)
	rcall	delay

#if _SFR_ASM_COMPAT == 0
	cbi	\portx,\bit
#else
	cbi	_SFR_IO_ADDR(\portx),\bit
#endif
	ldi	r16,lo8(__79088)
	ldi	r17,hi8(__79088)
	rcall	delay

	dec	r18
	brne	79078b

	ldi	r16,lo8(__79089)
	ldi	r17,hi8(__79089)
	rcall	delay
	rjmp	79075b
79076:
#endif
.endm

;---------------------------------------------------------------------
; bassert: Blink the LED r16 times, pause and repeat forever
;---------------------------------------------------------------------

.macro	bassert	blinks:req
#ifndef NDEBUG
	ldi	r16,\blinks
	rjmp	blinkn
#endif
.endm

;---------------------------------------------------------------------
; NOTES:
;
; 1) Flash Usage:
;
;	bassert initialization + 1 x bassert macro
;	ATtiny13A compiled without NDEBUG:
;		Overhead:	 38 bytes (interrupt vectors etc)
;		bassert:	 62 bytes
;		Total:		100 bytes
;	+ 2 bytes for each additional bassert macro used
;
;	ATtiny13A compiled with NDEBUG defined:
;		Overhead:	 38 bytes (interrupt vectors etc)
;		bassert:	  0 bytes
;		Total:		 38 bytes
;	+ 0 bytes for each additional bassert macro used
;
; 2) This module assumes that the LED is wired so that when the GPIO
;    pin is high, that the LED will be lit (active high).
;
; 3) The delay is crudely computed based upon the value of F_CPU.
;
; 4) Source code must be compiled by avr-gcc.
;
; 5) Works with __SFR_OFFSET defined, or not.
;
; 6) If you have the GPIO I/O configured already, it is not necessary
;    to execute the code in the bassert_init macro. However, the
;    macro must be used in the .text section to define the needed
;    support routines.
;
;---------------------------------------------------------------------
; End bassert.h
;---------------------------------------------------------------------

