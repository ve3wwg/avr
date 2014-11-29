;---------------------------------------------------------------------
; 8x8 Matrix Receiver Module (MAX7219 Chip)
; Warren W. Gay VE3WWG
; License: GPL v2 (see accompanying file LICENSE)
;
; With Fuses set to: H:FF, L:6A
; The system starts with internal RC Osc at ~ 8 MHz, divided by 8.
;
; After the main program sets the divisor to 1, the code runs at
; 8 MHz
;
; Worst case ISR run is approx 64 cycles (~ 8 usec)
;
; DATA FORMAT:
; MSB.....Data........LSB (12-bits, MSB first)
; D D D D 7 6 5 4 3 2 1 0
;
; DDDD is values 0x00 to 0x07 to select a digit.
;         Digit  0x08 selects intensity (values 0xX0 to 0xXF)
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

	.section .text
	.global	main
	.global	TIM0_COMPA_vect

;---------------------------------------------------------------------
; Configurable Items
;---------------------------------------------------------------------

PRESCALE	= 1	; Timer0 Prescaler (1 = no prescale)

#if F_MCU >= 8000000
OCR0A_COUNT	= 170	; Counter match value for 8 MHz MCU
#else
OCR0A_COUNT	= 245	; Counter match value for 4 Mhz MCU
#endif

BRIGHTNESS	= 0x01	; Matrix Brightness Level

;---------------------------------------------------------------------
; Manchester Data Input 
;---------------------------------------------------------------------

MCHDIN		= PB0	; Manchester Data In Pin
IPORTX		= PINB	; Manchester Port for MCHDIN
dbits		= 12	; Data bits to receive 4 + 8 bits

;---------------------------------------------------------------------
; Matrix LED outputs
;---------------------------------------------------------------------

DDRX		= DDRB
PORTX		= PORTB

; Outputs

CLK		= PB4	; Output to matrix clock input
DIN		= PB2	; Output to matrix data input
LOAD		= PB3	; Output to matrix CS/Load input
FLED		= PB1	; Fault LED

;---------------------------------------------------------------------
; Other register allocations
;---------------------------------------------------------------------

; Main routine arguments
#define ARG1		r16
#define ARG2		r17

; Main routine temps
#define TMP		r20
#define TM2		r21
#define DTMP		r22

; ISR Timer Count
#define	counterl 	r5
#define	counterh	r6
#define counterh2	r7
#define mdin		r11

; Receiver State
#define	rxstate		r19

; Receive time T (low and high)
#define	rxtimel		r8
#define rxtimeh		r9
#define rxtimeh2	r4

; Data received (low and high)
#define datal		r12
#define datah		r13

; Bit count
#define	bcount		r14

;---------------------------------------------------------------------
; State machine values
;---------------------------------------------------------------------

	.equiv	SREADY,0	; Ready state
	.equiv	S1ST0,1		; Waiting first 0-bit (start bit)
	.equiv	S1ST0B,2	; Wait for high to low transition (or timeout) during 1st 0-bit
	.equiv	SDBIT,3		; Data bit - stabilize level
	.equiv	SDBIT0,4	; Zero bit 1st half (low)
	.equiv	SDBIT0B,5	; Zero bit 2nd half (high)
	.equiv	SDBIT1,6	; One bit 1st half (high)
	.equiv	SDBIT1B,7	; One bit 2nd half (low)
	.equiv	SRX,8		; Data bits received (process)
	.equiv	SWAITH,9	; Wait signal High 

;---------------------------------------------------------------------
; Data storage
;---------------------------------------------------------------------

	.section .bss
byte0:	.fill	8		; 8 Byte buffer for display
intens:	.fill	1		; Display intensity (default 1)
fault:	.fill	1		; Fault tick count else zero

;---------------------------------------------------------------------
; Test if the counter has timed out
; Compare rxtimet < counter ?  If so, set C=1
;---------------------------------------------------------------------
	.text

tcompr:	mov	r0,rxtimel
	mov	r1,rxtimeh	; r1:r0 = rxtimet
	mov	r15,rxtimeh2

	lsr	r15
	ror	r1
	ror	r0
	lsr	r15
	ror	r1
	ror	r0

	add	r0,rxtimel
	adc	r1,rxtimeh	; r1:r0 = rxtimet + 0.25 * rxtimet
	adc	r15,rxtimeh2

	cp	r0,counterl
	cpc	r1,counterh	; r1:r0 < r17:r16  ?
	cpc	r15,counterh2
	ret

;---------------------------------------------------------------------
; Test if time T has passed
;---------------------------------------------------------------------

wtime:	mov	r16,rxtimel
	mov	r17,rxtimeh
	mov	r18,rxtimeh2
	cp	r16,counterl
	cpc	r17,counterh
	cpc	r18,counterh2
	ret
	ret			; C=1 when counter > rxtime

;---------------------------------------------------------------------
; READY State - Wait High to Low transition for start of 1st 0-bit
;---------------------------------------------------------------------

jready:	tst	mdin		; See if we got a Low Siganl
	breq	2f		; Branch if low
	ret			; Else no change

2:	ldi	r16,dbits
	mov	bcount,r16	; 1 + 12 bits to receive

	clr	datal
	clr	datah		; datah:datal = 0x0000

	ldi	r16,S1ST0	; Got the expected Signal = Low
	rjmp	rchstate

;---------------------------------------------------------------------
; Wait for low to high transition for 1st 0-bit
;---------------------------------------------------------------------

j1st0:	tst	mdin
	brne	2f		; Branch if got high
	ret

2:	mov	rxtimel,counterl ; Capture timer:
	mov	rxtimeh,counterh ;   rxtimer = counter
	mov	rxtimeh2,counterh2 ;  more precision

	ldi	r16,S1ST0B	; State - 2nd half of 0-bit
	rjmp	rchstate	; Clear counter + change state

;---------------------------------------------------------------------
; Wait for 2nd half of 0-bit (during high)
;---------------------------------------------------------------------

j1st0b:	tst	mdin
	breq	2f		; Start data 0-bit
	rcall	wtime		; Wait for 2nd half of 0-bit (high period)
	brcs	2f		; Start data 1-bit
	ret			; Signal still high

2:	ldi	r16,SDBIT	; State - start of data bit
	rjmp	rchstate	; Clear counter and change state

;---------------------------------------------------------------------
; Turn on Fault LED and reset state
;---------------------------------------------------------------------

fail:	ldi	r16,255
	sts	fault,r16	; Clear fault LED after this count reaches zero
	sbi	PORTX,FLED	; Turn on the fault LED
	ldi	r16,SWAITH	; Recovery state
	rjmp	chstate		; Change state without resetting counter

;---------------------------------------------------------------------
; Start a data bit: next state depends upon stable line level
; Low -> collect 0-bit  else  High -> collect 1-bit
;---------------------------------------------------------------------

jdbit:	tst	mdin
	breq	2f		; Signal went low 
	ldi	r16,SDBIT1	; Collect a 1-bit
	rjmp	chstate		; Try to collect a one bit

2:	ldi	r16,SDBIT0	; Collect a 0-bit
	rjmp	chstate		; Try to collect a zero bit

;---------------------------------------------------------------------
; Collect a zero bit (first half - at low level)
; There must be a transition from low to high here.
;---------------------------------------------------------------------

jdbit0:	tst	mdin		; Wait for transition to high
	brne	1f		; Branch if we see High
	rcall	tcompr		
	brcs	fail		; Timed out on 0-bit low period
	ret

1:	ldi	r16,SDBIT0B	; Now wait out 2nd half
	rjmp	rchstate	; wait out 2nd half

;---------------------------------------------------------------------
; Wait out 2nd half of zero bit (level = high).
; This state ends with a transition to low, or expiry of time T
;---------------------------------------------------------------------

jdbit0b: tst	mdin		; Wait for transition to low
	breq	3f		; Branch if signal went low
	rcall	wtime
	brcs	3f		; Else stop waiting at T
	ret

3:	clt			; T=0

dfin:	lsl	datal		; Shift data regs left
	rol	datah
	bld	datal,0		; Or in bit: datal.0 = T

	dec	bcount		; One less data bit to receive
	breq	5f
	ldi	r16,SDBIT	; Go get next bit
	rjmp	rchstate

5:	ldi	r16,SRX		; Data now received
	rjmp	chstate		; Receive data

;---------------------------------------------------------------------
; Collect a one data bit (1st half - at high level)
; Here we must get the transition from high to low.
;---------------------------------------------------------------------

jdbit1:	tst	mdin		; Wait for transition to low
	breq	1f		; Branch if we got low
	rcall	tcompr
	brcs	fail		; Fail: timed out
	ret

1:	ldi	r16,SDBIT1B	; Wait out 2nd half
	rjmp	rchstate

;---------------------------------------------------------------------
; Wait out 2nd half of 1-bit (while level low)
;---------------------------------------------------------------------

jdbit1b: tst	mdin		; Wait for a transition to high
	brne	3f		; Branch if line gone high
	rcall	wtime
	brcs	3f		; Expiry of time T
	ret

3:	set			; T=1
	rjmp	dfin

;---------------------------------------------------------------------
; Wait until line = High
;---------------------------------------------------------------------

jwaith:	tst	mdin		; Check if stable line high
	brne	1f
	ret			; Stay in current state

1:	ldi	r16,SREADY
	rjmp	rchstate	; State = SREADY

;---------------------------------------------------------------------
; Data word received:
;  datah lower 4 bits has digit (data byte)
;---------------------------------------------------------------------

jrx:	mov	ZL,datah
	andi	ZL,0x0F		; Mask out lower 4 bits (digit #)
	cpi	ZL,8+1		; 8 == Intensity
	brcc	fail

	ldi	r16,lo8(byte0)
	add	ZL,r16
	ldi	ZH,hi8(byte0)
	st	Z,datal		; Save data byte to bytex

	ldi	r16,SWAITH
	rjmp	rchstate	; Now go to next state

;---------------------------------------------------------------------
; Change State
;---------------------------------------------------------------------

rchstate:
	clr	counterl
	clr	counterh	; counter = 0
	clr	counterh2
chstate: mov	rxstate,r16	; Change to state in r16
	ret

;---------------------------------------------------------------------
; State Jump Table
;---------------------------------------------------------------------

jmptab:	rjmp	jready		; 0 : Ready
	rjmp	j1st0		; 1 : Time low during 1st 0-bit
	rjmp	j1st0b		; 2 : Wait for high to low
	rjmp	jdbit		; 3 : Wait for data bit to stabilize
	rjmp	jdbit0		; 4 : Wait for first half of zero bit
	rjmp	jdbit0b		; 5 : Wait for 2nd half of zero bit
	rjmp	jdbit1		; 6 : Wait for first half of one bit
	rjmp	jdbit1b		; 7 : Wait for 2nd half of one bit
	rjmp	jrx		; 8 : Received data
	rjmp	jwaith		; 9 : Wait until signal = High

;---------------------------------------------------------------------
; Timer 0 ISR Routine
;---------------------------------------------------------------------

TIM0_COMPA_vect:
	push	r16		; r16
	in	r16,SREG	; 
	push	r16		; SREG
	push	r17		; r17

	clr	mdin		; mdin = 0
	sbic	IPORTX,MCHDIN	; Test if MCHDIN is set
	inc	mdin		; mdin = 1

	lds	r16,fault	; Don't change counter if faulted
	tst	r16
	breq	1f		; Branch if no fault 

	dec	r16		; Decrement fault count
	sts	fault,r16	; Save it
	brne	1f		; Branch if fault not cleared yet

	cbi	PORTX,FLED	; Turn off Fault LED

1:	inc	counterl	; Normally, we increment our tick
	brne	2f		;  counter
	inc	counterh
	brne	2f
	inc	counterh2

2:	ldi	ZL,lo8(pm(jmptab))
	ldi	ZH,hi8(pm(jmptab))
	add	ZL,rxstate	; Add rx state
	icall			; Call state routine (thru Z)

8:	pop	r17		; r17
	pop	r16		; SREG
	out	SREG,r16
	pop	r16		; r16
	reti
	
;---------------------------------------------------------------------
; Write the Carry bit out to the MAX7219 device
;---------------------------------------------------------------------

wrbit:	cbi	PORTX,CLK	; CLK = low
	brcs	1f
	cbi	PORTX,DIN	; DIN = low
	rjmp	2f
1:	sbi	PORTX,DIN	; DIN = high
2:	sbi	PORTX,CLK	; CLK = high
	ret

;---------------------------------------------------------------------
; Write a byte in r0 to MAX7219 device
;---------------------------------------------------------------------

wrbyte:	ldi	DTMP,8
1:	rol	r10
	rcall	wrbit
	dec	DTMP
	brne	1b
	ret

;---------------------------------------------------------------------
; Write ARG2 (digit) & ARG1 (data) to MAX7219 device
;---------------------------------------------------------------------

wrdev:	cbi	PORTX,LOAD
	mov	r10,ARG2
	rcall	wrbyte
	mov	r10,ARG1
	rcall	wrbyte
	sbi	PORTX,LOAD
	ret

;---------------------------------------------------------------------
; Write register ARG2 (zero based digit) from ARG1, preserve ARG1 & ARG2
;---------------------------------------------------------------------

rxwrite:
	push	ARG2		; Zero based digit 0-7
	push	ARG1		; Data to be displayed
	inc	ARG2		; Make it digits 1-8 for MAX7219 chip
	rcall	wrdev
	pop	ARG1
	pop	ARG2
	ret

;---------------------------------------------------------------------
; Update MAX7219 Matrix display
;---------------------------------------------------------------------

udisp:	lds	ARG1,intens	; Has intensity been set?
	bst	ARG1,7		; High bit on? (T)
	brts	1f		; Yes, intensity has been set

	ori	ARG1,0x80	; Mark as completed
	sts	intens,ARG1	; Save as completed

	andi	ARG1,0x0F	; Mask out all but low 4 bits
	ldi	ARG2,9		; Intensity register (incremented to 0x0A)
	rcall	rxwrite		; Transmit to matrix

1:	ldi	YL,lo8(byte0)
	ldi	YH,hi8(byte0)	; Y = Address byte0
	clr	r24		; Digit
	ldi	r23,8		; Count

iloop:	ld	ARG1,Y+		; Get bytex
	mov	ARG2,r24	; Set digit to display
	rcall	rxwrite		; Transmit to matrix

	inc	r24		; Next digit
	dec	r23		; One less digit
	brne	iloop		; Loop until 8 done
	ret

;---------------------------------------------------------------------
; Initialize to Start 8-Bit Timer 0 (Manchester biphase receiver),
; and initialize MAX7219 driver chip.
;---------------------------------------------------------------------

rxinit:	sbi	DDRX,DIN	; Configure DIN as output
	sbi	DDRX,CLK	; Configure CLK as output
	sbi	DDRX,LOAD	; Configure LOAD as output
	sbi	DDRX,FLED	; Fault LED as output

	cbi	PORTX,DIN	; DIN = low
	cbi	PORTX,CLK	; CLK = low
	cbi	PORTX,LOAD	; LOAD = low
	cbi	PORTX,FLED	; Fault LED off

	ldi	ARG2,0x0C	; MAX7219 Shutdown
	ldi	ARG1,BRIGHTNESS	; 1=Normal
	rcall	wrdev

	clr	ARG2
	clr	ARG1		; Delay some to allow coming out of
1:	dec	ARG1		;  shutdown mode
	brne	1b
	dec	ARG2
	brne	1b

	ldi	ARG2,0x0F	; MAX7219
	clr	ARG1		;   test mode = off
	rcall	wrdev

	ldi	ARG2,0x09	; MAX7219 Decode Mode
	clr	ARG1		;   0 = no decode
	rcall	wrdev

	ldi	ARG2,0x0A	; MAX7219
	ldi	ARG1,0x02	;   Intensity = 2
	rcall	wrdev

	ldi	ARG2,0x0B	; MAX7219 Scan limit
	ldi	ARG1,0x07	;   All 7 digits are visible
	rcall	wrdev

;---------------------------------------------------------------------
; Clear SRAM Areas
;---------------------------------------------------------------------

	ldi	YL,lo8(byte0)	; Data display areas
	ldi	YH,hi8(byte0)
	ldi	r16,8

	clr	r0		; Clear Fault
	sts	fault,r0	;  status byte

1:	st	Y+,r0		; byte[Y+] = 0
	dec	r16
	brne	1b

	ldi	r16,1
	sts	intens,r16	; Initialize = 1

;---------------------------------------------------------------------
; Machester Receiver Initialization
;---------------------------------------------------------------------

	cbi	DDRX,MCHDIN	; Configure this pin as input
	sbi	PORTX,MCHDIN	; Configure this pin with pullup

	clr	rxtimel
	clr	rxtimeh		; T = 0 (no timings done yet)
	clr	rxtimeh2

	clr	counterl
	clr	counterh	; Counter = 0
	clr	counterh2

	clr	mdin
;	sbic	PINB,MCHDIN	; Test input line level
;	inc	mdin		; Set to 1 if MCHDIN = high

	ldi	rxstate,SWAITH	; Initial rxstate = SWAITH

;---------------------------------------------------------------------
; Initialize and start Timer 0 interrupts
;---------------------------------------------------------------------

	cli
	clr	r10
	out	TCCR0B,r10	; Stop timer 0
	out	TIMSK0,r10	; All timer0 interrupts off

	ldi	r16,(1<<OCF0B)|(1<<OCF0A)|(1<<TOV0)
	out	TIFR0,r16	; Clear any pending timer0 interrupt flags

	ldi	r16,OCR0A_COUNT
	out	OCR0A,r16	; Set OCR0A
	out	TCNT0,r10	; Zero timer0 counter

	ldi	r16,1<<WGM01	; WGM01=1, WGM00=0 (Clear counter on match mode)
	out	TCCR0A,r16

	ldi	r16,1<<OCIE0A 	; OCIE0A=1
	out	TIMSK0,r16	; Enable Compare A Interrupts

	ldi	r16,PRESCALE
	out	TCCR0B,r16	; Start timer (load prescaler)

	sei			; Enable global interrupts again
	ret

;---------------------------------------------------------------------
; Main program - refreshes Display
;---------------------------------------------------------------------

main:	cli
	ldi	r16,0b10000000
	ldi	r17,0b00000000	; Select "full speed" for ATtiny13
	out	CLKPR,r16	; Start clock prescale change
	out	CLKPR,r17	; Set clock prescale
	sei

	out	ADCSRA,r10	; Turn off ADC to save power
	cbi	ACSR,ACIE	; Disable Compare interrupts
	sbi	ACSR,ACD	; Turn off power to the Analog Comparator

        rcall   rxinit          ; Initialize data receiver

;---------------------------------------------------------------------
; Main loop
;---------------------------------------------------------------------

dloop:	rcall	udisp		; Display loop
	rjmp	dloop

;---------------------------------------------------------------------
; Register map
;---------------------------------------------------------------------
;	
;	REG	ISR		ALIAS		MAIN
;	
;	r0	scratch
;	r1	scratch
;	r2	rxtimer
;	r3	rxtimer+1	rxtimerh
;	r4	rxtimer+2	rxtimerh2
;	r5	counter		counterl
;	r6	counter+1	counterh
;	r7	counter+2	counterh2
;	r8	rxtimet		rxtimel
;	r9	rxtimet+1	rxtimeh
;	r10					udisp
;	r11	mdin
;	r12	ldata
;	r13	hdata
;	r14	bcount
;	r15	scratch
;	
;	r16	ARG1				udisp
;	r17	ARG2				udisp
;	r18	scratch
;	r19	rxstate
;	r20	TMP				
;	r21	TM2				main
;	r22	DTMP				udisp
;	r23					udisp (iloop)
;	r24					udisp
;	r25				
;	r26/X	
;	r27/XH	
;	r28/Y					udisp, main
;	r29/YH					udisp, main
;	r30/Z	rxstate jmp + d store
;	r31/ZH	rxstate jmp + d store
;	
;---------------------------------------------------------------------
; End 8x8rx.S
;---------------------------------------------------------------------
