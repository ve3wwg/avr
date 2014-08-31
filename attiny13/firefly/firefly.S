;---------------------------------------------------------------------
; The ATtiny13A FireFly program by Warren W. Gay VE3WWG
;---------------------------------------------------------------------
; Each PB4..PB0 has a resistor in series with an LED. Each of these
; fire independently, using random times in a state machine. The
; length of time that the fireflys "play" is determined by the symbol
; stop, which is defined as a count. See below for how to calculate
; times.
;
; After the stop count is reached, the MCU goes into power down mode
; to preserve battery. A push button grounding the /RESET pin (1)
; will restart the MCU and allow it to run again until the stop 
; count is reached.
;
; The brightness of each LED is varied by software PWM control. The
; flashes vary between a twinkle and a "flash", or just a flash at
; random. The flashes have random ramp up and decay times for added
; visual interest.
;
; SOFTWARE LICENSE: GPL
;
; Use avr-gcc to compile.
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
#include <avr/io.h>

;
;	Set stop to a count value that determines how long the fireflies
;	keep active, before power down. Each count on ATtiny13A keeps the
;	state machine alive for about 8 seconds (3 minutes for a count of
;	22 (or 0x16)).
;
	.equ	stop,675	; 1.5 hours / 8 seconds => 675

	.section .text
	.global	main

	.global	TIM0_COMPA_vect

	.equ	x,r26

;---------------------------------------------------------------------
; Register cpp equivalents
;---------------------------------------------------------------------

#define x	r26
#define xl	r26
#define xh	r27
#define y	r28
#define	yl	r28
#define yh	r29	

	.data
;---------------------------------------------------------------------
; Timer 1 Counters : Each decremented when > 0 for each tick
;---------------------------------------------------------------------
	.equ	TIMER0,0	; r0,r1 is software timer 1
	.equ	TIMER1,2	; r2,r3 is software timer 2
	.equ	TIMER2,4	; ...
	.equ	TIMER3,6
	.equ	TIMER4,8	; r8, r9 is software timer 4

;---------------------------------------------------------------------
; Other register allocations
;---------------------------------------------------------------------
	.equ	T256,12		; r12 is the ISR divide by 256 counter
	.equ	ISRTMP,16	; r16 is the ISR temp register
	.equ	ISRTM2,17	; r17 is the ISR temp 2 register
	.equ	MTMP,18		; Main temp is r18
	.equ	MLED,19		; Main LED #
	.equ	MTMP2,23	; Main temp 2 (r23)
	.equ	MTMP3,22
	.equ	LEDOUT,24	; r14 is the ISR LED output bits
	.equ	LEDC,25		; r13 is the ISR LED counter
	.equ	PRESCALE,0x01	; Timer0 Prescaler to use
	.equ	ARG1,MTMP	; Argument 1 (non-ISR)
	.equ	ARG2,MTMP2	; Argument 2 (non-ISR)
	.equ	ARG3,MTMP3
	.equ	TMRDIV,8

;---------------------------------------------------------------------
; State machine storage (SRAM)
;---------------------------------------------------------------------
PWM0:	.byte	0,0,0,0		; Members: PWM_N, PWM_C, STATE, STTMR
PWM1:	.byte	0,0,0,0
PWM2:	.byte	0,0,0,0
PWM3:	.byte	0,0,0,0
PWM4:	.byte	0,0,0,0
ZZZ1:	.byte	0,0		; Times before sleeping counter

;---------------------------------------------------------------------
; Offset definitions for the state structure
;---------------------------------------------------------------------
	.equ	PWM_N,0		; PWM counter for LED
	.equ	PWM_C,1		; PWM Compare value
	.equ	STATE,2		; State of this LED
	.equ	STTMR,3		; Step time for this State

	.equ	SZ,4		; State size in bytes

;---------------------------------------------------------------------
; Dual Purpose Timer 0 ISR:
;	
; (1)	Decrement each counter count0 thru count5. Any counter
;	found holding zero, is left as zero.
; (2)	Else advance each LED PWM state
;---------------------------------------------------------------------
	.text

TIM0_COMPA_vect:
	in	ISRTMP,SREG	; Capture SREG
	push	ISRTMP		; Save SREG
	push	yl		; Save Y low
	push	yh		; Save Y high
;
	dec	T256		; Update software timers 1/256 of the time
	brne	dopwm		; Branch until T256 is zero
	ldi	ISRTMP,TMRDIV
	mov	T256,ISRTMP	; T256 = TMRDIV

;---------------------------------------------------------------------
; Decrement non-zero software timer cells
;---------------------------------------------------------------------

	movw	y,TIMER0
	sbiw	y,1
	brcs	1f
	movw	TIMER0,y
1:	movw	y,TIMER1
	sbiw	y,1
	brcs	2f
	movw	TIMER1,y
2:	movw	y,TIMER2
	sbiw	y,1
	brcs	3f
	movw	TIMER2,y
3:	movw	y,TIMER3
	sbiw	y,1
	brcs	4f
	movw	TIMER3,y
4:	movw	y,TIMER4
	sbiw	y,1
	brcs	isrxit
	movw	TIMER4,y
	rjmp	isrxit

;---------------------------------------------------------------------
; Else advance the LED PWM state
;---------------------------------------------------------------------

dopwm:	ldi	yh,hi8(PWM0)
	ldi	yl,lo8(PWM0)
	ldi	LEDC,5		; 5 LEDs to track state for
	ldi	LEDOUT,0	; Clear LED output bits
;
;	Update PWM Counter (Up)
;
ledlp:	ldd	ISRTMP,Y+PWM_N		; Load 8-bit PWM count
	inc	ISRTMP			; Increment PWM count
	std	Y+PWM_N,ISRTMP		; Save r24 : Update PWM count 
;
;	Determine LED state from PWM count vs Compare
;
	ldd	ISRTM2,Y+PWM_C		; Load compare count
	cp	ISRTM2,ISRTMP		; Compare < Count?
	brcs	3f			; Branch if PWM count > Compare count
	breq	3f			; Branch if equal (allows LED to be completely dark)
	ori	LEDOUT,0b00100000	; Set bit 6 (to be shifted right)
;
;	Prepare for next iteration
;
3:	adiw	y,SZ			; Advance to next PWM control set
	ror	LEDOUT			; shift LED bits right (5 ---> 0 eventually)
	dec	LEDC
	brne	ledlp
;
;	Set Outputs for LEDs
;
	out	PORTB,LEDOUT		; Output bits to LED pins
;
isrxit:	pop	yh
	pop	yl
	pop	ISRTMP
	out	SREG,ISRTMP
	reti
	
;---------------------------------------------------------------------
; Initialize to Start 8-Bit Timer 0
;---------------------------------------------------------------------
init:	cli			; Disable interrupts for now
;
;	Clear software timers
;
	ldi	ISRTMP,0
	mov	TIMER0,ISRTMP
	mov	TIMER0+1,ISRTMP
	mov	TIMER1,ISRTMP
	mov	TIMER1+1,ISRTMP
	mov	TIMER2,ISRTMP
	mov	TIMER2+1,ISRTMP
	mov	TIMER3,ISRTMP
	mov	TIMER3+1,ISRTMP
	mov	TIMER4,ISRTMP
	mov	TIMER4+1,ISRTMP
	mov	T256,ISRTMP	; Clear timer divisor
;
;	Configure Timer 0 for Interrupts
;
	out	TCCR0B,ISRTMP	; Stop timer 0
	sts	TIMSK0,ISRTMP	; All timer0 interrupts off
	ldi	ISRTM2,0b00001110
	out	TIFR0,ISRTM2	; Clear any pending timer0 interrupt flags
	ldi	ISRTM2,90	; OCR0A
	out	OCR0A,ISRTM2	; Set OCR0A
	out	TCNT0,ISRTMP	; Zero timer0 counter

	ldi	ISRTM2,0b00000010 ; 
	out	TCCR0A,ISRTM2

	ldi	ISRTM2,0b00000100 ; OCIE0A=1
	out	TIMSK0,ISRTM2	; Enable Compare A Interrupts

	ldi	ISRTM2,PRESCALE
	out	TCCR0B,ISRTM2	; Start timer (load prescaler)

	ldi	ISRTMP,0b10000000
	ldi	ISRTM2,0b00000000
	out	CLKPR,ISRTMP	; Start clock prescale change
	out	CLKPR,ISRTM2	; Set clock prescale

	sei			; Enable global interrupts again
	ret

;---------------------------------------------------------------------
; Main Firefly Program
;---------------------------------------------------------------------

main:	ldi	MTMP,0b00011111	; PB4..PB0
	out	DDRB,MTMP	; Configure PB4..PB0 as outputs
	ldi	MTMP,0
	out	PORTB,MTMP	; Turn off all LEDs for now

	out	ADCSRA,MTMP	; Turn off ADC to save power
	cbi	ACSR,ACIE	; Disable Compare interrupts
	sbi	ACSR,ACD	; Turn off power to the Analog Comparator
;
;	Clear TIMERx and LED PWM state
;
	ldi	xh,hi8(TIMER0)
	ldi	xl,lo8(TIMER0)
	ldi	yh,hi8(PWM0)
	ldi	yl,lo8(PWM0)
	ldi	MTMP,0
	sts	ZZZ1,MTMP
	sts	ZZZ1+1,MTMP	; ZZZ1 = 0
	ldi	LEDC,5
1:	st	X+,MTMP
	st	X+,MTMP
	std	Y+PWM_N,MTMP
	std	Y+PWM_C,MTMP
	std	Y+STATE,LEDC
	std	Y+STTMR,LEDC
	adiw	y,SZ
	dec	LEDC
	brne	1b
;
	sei			; Enable interrupts
	rcall	init		; Initialize and start timer 0
	rcall	rinit		; Initialize random number generator

;---------------------------------------------------------------------
; Main Program State Machine: Control brightness of LEDs and 
; change state over time.
;---------------------------------------------------------------------

	ldi	xh,hi8(TIMER0)	; hi(TIMER0) = 0x00
	ldi	yh,hi8(PWM0)	; YH remains constant

restart: ldi	MLED,5		; Count of LEDs being serviced
	ldi	xl,lo8(TIMER0)	; X = &TIMER0
	ldi	yl,lo8(PWM0)	; Y = &PWM0

sloop:	rcall	wait		; Test if TIMERx is zero
	breq	dostate		; If so, then do state stuff
	rjmp	nxtled		; Else try next LED state

dostate: ldd	MTMP,Y+STATE	; Get current state
	cpi	MTMP,0		; State = 0?
	breq	state0		; Start to brighten
	cpi	MTMP,1
	breq	state1		; Increase brightness
	cpi	MTMP,2
	breq	state2		; Hold for a spell
	cpi	MTMP,3
	breq	state3		; Decrease brightness
	cpi	MTMP,4
	breq	state4		; Off for a spell
	cpi	MTMP,5
	breq	state5
	cpi	MTMP,6
	breq	to6		; Extra delay
	cpi	MTMP,7
	breq	to7		; Extra delay

nxtled:	adiw	x,2		; Advance to next &TIMERx
	adiw	y,SZ		; Advance to next &PWM struct
	dec	MLED
	brne	sloop		; Test next TIMERx 
	rjmp	restart		; Else start the loop over

;---------------------------------------------------------------------
; State 0 just launches state 1
;---------------------------------------------------------------------

state0:	ldi	MTMP,1
	std	Y+PWM_C,MTMP	; PWMx.PWM_C = 1
	rcall	rand		; ARG2, ARG1 is random
	bst	ARG2,0		; Test hi8(r) bit 0
	brtc	go3		; Go to state 3 if hi8(r).0 is set
	inc	ARG1
	andi	ARG1,0x07	; Randomize startup time
	ldi	ARG2,1		; New STATE value
	rjmp	newst		; Initialize to state 1

;---------------------------------------------------------------------
; State 1 increases brightness until we reach PWMx.PWM_C = 255
;---------------------------------------------------------------------

state1:	ldd	MTMP,Y+PWM_C
	cpi	MTMP,255	; PWMx.PWM_C == 255?
	breq	1f
	inc	MTMP
	std	Y+PWM_C,MTMP	; ++PWM_C
	rjmp	stay		; Stay in this state for another big tick

1:	rcall	rand		; ARG2, ARG1 is random
	andi	ARG1,0x0F
	inc	ARG1
	ldi	ARG2,2		; STATE = 2
	rjmp	newst		; Change to state 2

;---------------------------------------------------------------------
; State 2 we decrement PWM_C quickly to about 30/255
;---------------------------------------------------------------------

state2:	ldd	MTMP,Y+PWM_C
	dec	MTMP
	std	Y+PWM_C,MTMP	; --PWMx.PWM_C
	cpi	MTMP,30
	breq	go3
	rjmp	stay

go3:	rcall	rand		; ARG2, ARG1 is random
	andi	ARG1,0x1F	; Random 
	inc	ARG1
	ldi	ARG2,3		; STATE = 3
	rjmp	newst

;---------------------------------------------------------------------
; State 3 we increment PWM_C to increase brightness to 100%
;---------------------------------------------------------------------

state3:	ldd	MTMP,Y+PWM_C
	cpi	MTMP,255
	breq	3f
	inc	MTMP
	std	Y+PWM_C,MTMP	; --PWMx.PWM_C
	rjmp	stay

3:	rcall	rand
	andi	ARG1,0x3F
	inc	ARG1		; TIMERx = ..
	ldi	ARG2,4		; STATE = 4
	rjmp	newst

;---------------------------------------------------------------------
; State 4 - decrease brightness slowly
;---------------------------------------------------------------------

state4:	ldd	MTMP,Y+PWM_C
	dec	MTMP
	std	Y+PWM_C,MTMP	; --PWMx.PWM_C
	breq	4f
	rjmp	stay

4:	rcall	rand
	ldi	ARG1,250	; TIMERx = x
	ldi	ARG2,5		; STATE = 5
	rjmp	newst

to6:	rjmp	state6
to7:	rjmp	state7

;---------------------------------------------------------------------
; State 5 we delay for a while before restarting state 0
;---------------------------------------------------------------------

state5:	ldd	MTMP,Y+STTMR
	or	MTMP,MTMP
	breq	5f
	dec	MTMP
	std	Y+STTMR,MTMP
	rjmp	stay

5:	ldi	ARG1,250
	ldi	ARG2,6
	rjmp	newst

;---------------------------------------------------------------------
; State 6 - Extra delay
;---------------------------------------------------------------------

state6:	ldd	MTMP,Y+STTMR
	or	MTMP,MTMP
	breq	6f
	dec	MTMP
	std	Y+STTMR,MTMP
	rjmp	stay

6:	rcall	rand
	andi	ARG1,0x7F
	ldi	ARG2,7
	rjmp	newst

;---------------------------------------------------------------------
; State 7 - Extra random delay
;---------------------------------------------------------------------

state7:	ldd	MTMP,Y+STTMR
	or	MTMP,MTMP
	breq	7f
	dec	MTMP
	std	Y+STTMR,MTMP
	rjmp	stay
;
;	Test if this is LED 1, then count for ZZZ
;
7:	cpi	MLED,1		; Is this LED 0? (offset by +1)
	brne	8f		; No, do normal stay action
;
;	Count and test if it is time to power down
;
	lds	MTMP,ZZZ1	; Load low byte of count
	lds	MTMP2,ZZZ1+1	; Load high byte of count

	inc	MTMP		; Increment count
	sts	ZZZ1,MTMP	; Save low byte of count
	brne	9f		
	inc	MTMP2		; Increment high byte of count
	sts	ZZZ1+1,MTMP2	; Save it
;
;	Compare counter to stop count
;
9:	cpi	MTMP2,hi8(stop)	; Compare high byte first
	brne	8f
	cpi	MTMP,lo8(stop)	; Compare low byte
	breq	dim		; Branch if time to sleep

8:	ldi	ARG1,25
	ldi	ARG2,0
	rjmp	newst

;---------------------------------------------------------------------
; Put all fireflies to sleep (slowly dim them until all are dark)
;---------------------------------------------------------------------

dim:	ldi	MLED,5		; Count of LEDs being serviced
	ldi	xl,lo8(TIMER0)	; X = &TIMER0
	ldi	yl,lo8(PWM0)	; Y = &PWM0
	set			; T = 1
	ldi	MTMP,253
	sts	TIMER0,MTMP	; TIMER0 = 253

wloop:	rcall	wait		; Wait on timer0
	brne	wloop		; Wait for timer 0

3:	ldd	MTMP,Y+PWM_C
	tst	MTMP		; Y+PWM_C == 0?
	breq	2f		; Branch if true
	clt			; Else T = 0
	dec	MTMP		; Decrease brightness
	std	Y+PWM_C,MTMP	; Effectively: --(Y+PWM_C)

2:	adiw	y,SZ		; Advance to next state
	dec	MLED		; One less LED
	brne	3b		; Test next LED
	brtc	dim		; Not all LEDs dimmed yet

;---------------------------------------------------------------------
; Put the MCU into sleep mode
;---------------------------------------------------------------------

sleep:	ldi	MTMP,0b00000000	
	out	PORTB,MTMP	; Make certain all LEDs off
	ldi	MTMP,0x00
	sts	TIMSK0,MTMP	; Disable timer 0 interrupts
;
;	Power Down (until /RESET)
;
	ldi	MTMP,0b00110000	; SE + Power-down mode
	out	MCUCR,MTMP
1:	sleep
	rjmp	1b		; This statement should never execute

;---------------------------------------------------------------------
; Start a new state for LED # MLED
;---------------------------------------------------------------------

newst:	st	X,ARG1		; TIMERx = new timer value
	std	Y+STTMR,ARG1	; PWMx.STTMR = ARG1
	std	Y+STATE,ARG2	; PWMx.STATE = new state #
	rjmp	nxtled

;---------------------------------------------------------------------
; Maintain state: Refresh the TIMERx
;---------------------------------------------------------------------

stay:	ldd	MTMP,Y+STTMR	; MTMP = PWMx.STTMR
	st	X,MTMP		; TIMERx = PWMx.STTMR
	rjmp	nxtled

;---------------------------------------------------------------------
; Wait for software timer 0-4 (ARG1) to Zero
;
; ARG1:	0-4 for Timer #
; Returns Z flag if counter is zero
;---------------------------------------------------------------------

wait:	ld	MTMP,X		; MTMP = lo(TIMERx)
	tst	ARG1		; low count test
	brne	1f		; Counter not zero
	inc	xl		; Point to high byte of counter
	ld	MTMP,X
	dec	xl		; Restore XL
	tst	MTMP		; High count zero?
1:	ret

;---------------------------------------------------------------------
; Generate a random 16-bit value
;---------------------------------------------------------------------

	.data
r:	.word	0xACE1		; Random value 16-bit

	.equ	rl,r
	.equ	rh,r+1

	.text
rand:	lds	ARG1,rl		; Load saved r low
	lds	ARG2,rh		; Load saved r high
	lsr	ARG2		; rh >> 1 
	ror	ARG1		; rl >> 1 and C = LSB
	brcc	1f
	ldi	ARG3,0xB4
	eor	ARG2,ARG3	; r ^= 0xB400
1:	sts	rl,ARG1		; Save r low
	sts	rh,ARG2		; and r high
	ret

rinit:	ldi	ARG1,0xE1	; Initialize r = ACE1
	sts	rl,ARG1
	ldi	ARG1,0xAC
	sts	rh,ARG1
	ret

;---------------------------------------------------------------------
; End firefly.S
;---------------------------------------------------------------------
