;---------------------------------------------------------------------
; Toggle Push Button 4 : Debounce Button and Toggle LED (quick)
;
; Warren W. Gay VE3WWG	Fri Oct 24 21:31:37 2014
; GPL v2 License (See file LICENSE)
;
; In this program, we configure PB2 as an output (active high)
; for the LED. When the button is pushed, the LED will be toggled.
;
; GPIO PB0 is configured as input, with the pullup resistor
; enabled. When the button is pushed (connected to ground),
; PB0 will read as 0. The tricky part here is to debounce the LED
; for reliable toggle operation.
;
; DEBOUNCE METHOD:
;
; This program uses the simple idea of starting a counter at the
; midpoint value of 0x8000. If the button is read as 0, then the
; count is decremented, else it is incremented. The count will 
; go up and down, as the contacts bounce, making and breaking a
; connection. Eventually in time, the contacts will settle with
; a solid connection (when pressed), causing the count to decrement
; to zero (registering a button press). Alternatively, the contacts
; will eventually disconnect completely, allowing the count to 
; increment up and overflow to zero (registering a button release).
;
; CONCLUSION:
;
; This program improves the button response time without giving up
; reliable contact debouncing. Program togglepb3.S was enhanced by
; the addition of compare operations [1] and [2]. Rather than wait
; for the compare routines to count down/up to zero, they count 
; down/up to values closer to 0x8000. This reduces the button 
; wait time (and probably could be tuned still further).
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 		/* Avoid _SFR_IO() macro */
	.nolist
#include <avr/io.h>
	.list

	.text
	.global	main
;
;	Read debounced pushed button state
;
readpb:	clr	r18		; Counter in r19:r18
	ldi	r19,0x80	;  = 0x8000

1:	bclr	6		; Set T=0
	sbis	PINB,PB0	; Test PINB.PB0
	bset	6		; Set T=1
	brtc	2f		; Branch if button not pushed (T=0)

	dec	r18		; Decrement counter r19:r18
	brne	1b		;  until we reach zero
	dec	r19
	cpi	r19,0x70	; Have we gone far enough? [1]
	brne	1b		; Loop back if not
	bset	6		; T=1
	ret

2:	inc	r18		; Increment counter r19:r18
	brne	1b		;  until we reach zero
	inc	r19
	cpi	r19,0x90	; Have we gone far enough? [2]
	brne	1b		; Loop back if not
	bclr	6		; T=0 (button unpushed)
	ret
;
;	Main program
;
main:	sbi	DDRB,PB2	; PB2 (LED) is output
	cbi	DDRB,PB0	; PB0 (Button) is input
	cbi	PORTB,PB2	; LED off
	sbi	PORTB,PB0	; Pullup on
	clr	r20		; Save state (r20=0x00)

1:	rcall	readpb		; Read button state into T flag
	brtc	1b		;  Branch if button not pressed

	ldi	r16,0x01
	eor	r20,r16		; Toggle bit r20.0
	brne	2f

	cbi	PORTB,PB2	; Turn LED off
	rjmp	3f

2:	sbi	PORTB,PB2	; Turn LED on

3:	rcall	readpb
	brts	3b		; Loop until button released
	rjmp	1b		; T=0

;---------------------------------------------------------------------
; End togglepb4.S
;---------------------------------------------------------------------
