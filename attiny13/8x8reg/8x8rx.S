;---------------------------------------------------------------------
; 8x8 Matrix Receiver Module (MAX7219 Chip)
; Warren W. Gay VE3WWG
; License: GPL v2 (see accompanying file LICENSE)
;
; With Fuses set to: H:FF, L:6A
; The system starts with internal RC Osc at 9.6 MHz, divided by 8.
;
; After the main program sets the divisor to 1, the code runs at
; 9.6 MHz (0.104 usec)
;
; Worst case ISR run is approx 64 cycles (~ 7 usec)
; See further notes at the bottom.
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

	.section .text
	.global	main
	.global	TIM0_COMPA_vect

; Timer0 Prescaler
#define	PRESCALE	1

; Counter match value
#define	OCR0A_COUNT	10

; Matrix Brightness Level
#define BRIGHTNESS	0x01

;---------------------------------------------------------------------
; Manchester Data Input 
;---------------------------------------------------------------------

; Manchester Data In Pin
#define MCHDIN		PB0

; Manchester Port for MCHDIN
#define IPORTX		PINB

; Must have 4 bits in agreement
#define MCHBMASK	0x0F

; Count of bits in MCHBMASK
#define MCHBCOUNT	4

; Data bits to receive 4 + 8 bits
#define	dbits		12

;---------------------------------------------------------------------
; Matrix LED outputs
;---------------------------------------------------------------------

; Output pins
#define DDRX		DDRB
#define PORTX		PORTB

; Outputs
#define CLK		PB4
#define DIN		PB2
#define LOAD		PB3

; Fault LED
#define FLED		PB1

;---------------------------------------------------------------------
; Other register allocations
;---------------------------------------------------------------------

; Main routine arguments
#define ARG1		r16
#define ARG2		r17

; Main routine temps
#define	TMP		r20
#define TM2		r21
#define	DTMP		r22

; ISR Timer Count
#define	counterl 	r5
#define	counterh	r6
#define mdin		r11

; Receiver State
#define	rxstate		r19

; Receive time T (low and high)
#define	rxtimel		r8
#define rxtimeh		r9

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
	.equiv	SFAULT,10	; Input signal Fault occurred

;---------------------------------------------------------------------
; Fault codes
;---------------------------------------------------------------------

	.equiv	FAULT01,0xF1	; Start 0-bit high period too short
	.equiv	FAULT03,0xF3	; Timed out on 0-bit low period
	.equiv	FAULT04,0xF4	; High came too soon for 0-bit
	.equiv	FAULT05,0xF5	; Data 0-bit ended too soon
	.equiv	FAULT06,0xF6	; Data 1-bit timed out during high period
	.equiv	FAULT07,0xF7	; Data 1-bit low came too soon
	.equiv	FAULT08,0xF8	; Data 1-bit low to high came too soon

;---------------------------------------------------------------------
; Data storage
;---------------------------------------------------------------------
	.data

byte0:	.byte	0		; For byte 0 of the matrix
byte1:	.byte	0
byte2:	.byte	0
byte3:	.byte	0
byte4:	.byte	0
byte5:	.byte	0
byte6:	.byte	0
byte7:	.byte	0		; Byte 7 of the matrix
fault:	.byte	0		; Fault value 

;---------------------------------------------------------------------
; Right shift (divide by 4) r1:r0
;---------------------------------------------------------------------

	.text

divby4:	lsr	r1
	ror	r0
	lsr	r1
	ror	r0
	ret

;---------------------------------------------------------------------
; Test if the counter has timed out
; Compare rxtimet < counter ?  If so, set C=1
;---------------------------------------------------------------------

tcompr:	mov	r0,rxtimel
	mov	r1,rxtimeh	; r1:r0 = rxtimet
	rcall	divby4		; r1:r0 /= 4

	add	r0,rxtimel
	adc	r1,rxtimeh	; r1:r0 = rxtimet + 0.25 * rxtimet

	cp	r0,counterl
	cpc	r1,counterh	; r1:r0 < r17:r16  ?
	ret

;---------------------------------------------------------------------
; Test if the counter is less than 1/2 of T (rxtimet)
;---------------------------------------------------------------------

thalf:	mov	r0,rxtimel
	mov	r1,rxtimeh
	lsr	r1
	ror	r0		; r1:r0 /= 2

	cp	r0,counterl
	cpc	r1,counterh	; r1:r0 < r17:r16  ?
	ret

;---------------------------------------------------------------------
; Test if time T has passed
;---------------------------------------------------------------------

wtime:	mov	r16,rxtimel
	mov	r17,rxtimeh

	cp	r16,counterl
	cpc	r17,counterh	; r1:r0 < r17:r16  ?
	brne	1f
	sec			; Set C=1 when values equal
1:	ret

;---------------------------------------------------------------------
; Expect Signal Low, High
;---------------------------------------------------------------------

getlo:	mov	r16,mdin
	andi	r16,0x0F
	ret

gethi:	mov	r16,mdin
	com	r16
	andi	r16,0x0F
	ret

;---------------------------------------------------------------------
; READY State - Wait High to Low transition for start of 1st 0-bit
;---------------------------------------------------------------------

jready:	rcall	getlo		; See if we got a Low Siganl
	breq	2f
	ret

2:	ldi	r16,dbits
	mov	bcount,r16	; 1 + 12 bits to receive

	clr	datal
	clr	datah		; datah:datal = 0x0000

	ldi	r16,S1ST0	; Got the expected Signal = Low
	rjmp	rchstate

;---------------------------------------------------------------------
; Wait for low to high transition for 1st 0-bit
;---------------------------------------------------------------------

j1st0:	rcall	gethi
	breq	2f		; Branch if got high
	ret

2:	mov	rxtimel,counterl ; Capture timer:
	mov	rxtimeh,counterh ;   rxtimer = counter

	ldi	r16,S1ST0B	; State - 2nd half of 0-bit
	rjmp	rchstate	; Clear counter + change state

;---------------------------------------------------------------------
; Wait for 2nd half of 0-bit (during high)
;---------------------------------------------------------------------

j1st0b:	rcall	getlo
	breq	1f		; Got a low, so advance state (start of next 0-bit)
	rcall	wtime		; Wait for 2nd half of 0-bit (high period)
	brcs	2f		; Start data 1-bit
	ret			; Signal still high

1:	rcall	thalf		; Did elapsed time exceed 1/2T as expected?
	brcc	3f		; Branch if transition came too soon

2:	ldi	r16,SDBIT	; State - start of data bit
	rjmp	rchstate	; Clear counter and change state

3:	ldi	r16,FAULT01	; 1st 0-bit high period too short
fail:
4:	sts	fault,r16	; Save fault code
	ldi	r16,SFAULT	; Change to fault state
	rjmp	chstate		; Change state without resetting counter

;---------------------------------------------------------------------
; Start a data bit: next state depends upon stable line level
; Low -> collect 0-bit  else  High -> collect 1-bit
;---------------------------------------------------------------------

jdbit:	rcall	getlo		; Stable low = 0xX0
	breq	2f		; Signal went low 
	cpi	r16,0x0F	; Stable high - 0xXF
	breq	3f		; Signal went high
	ret

2:	ldi	r16,SDBIT0	; Collect a 0-bit
	rjmp	chstate		; Try to collect a zero bit

3:	ldi	r16,SDBIT1	; Collect a 1-bit
	rjmp	chstate		; Try to collect a one bit

;---------------------------------------------------------------------
; Collect a zero bit (first half - at low level)
; There must be a transition from low to high here.
;---------------------------------------------------------------------

fail03:	ldi	r16,FAULT03	; Timed out on 0-bit low period
	rjmp	fail

fail04:	ldi	r16,FAULT04	; High came too soon for zero bit
	rjmp	fail

jdbit0:	rcall	gethi		; Wait for transition to high
	breq	1f		; Branch if we see High
	rcall	tcompr		
	brcs	fail03		; Timed out on 0-bit low period
	ret

1:	rcall	thalf
	brcc	fail04		; Level change came too soon

	ldi	r16,SDBIT0B	; Now wait out 2nd half
	rjmp	rchstate	; wait out 2nd half

;---------------------------------------------------------------------
; Wait out 2nd half of zero bit (level = high).
; This state ends with a transition to low, or expiry of time T
;---------------------------------------------------------------------

fail05:	ldi	r16,FAULT05	; 0-bit ended too soon
	rjmp	fail

jdbit0b: rcall	getlo		; Wait for transition to low
	breq	2f		; Branch if signal went low
	rcall	wtime
	brcs	3f		; Else stop waiting at T
	ret

2:	rcall	thalf
	brcc	fail05		; Level change came too soon

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

fail06:	ldi	r16,FAULT06	; 1-bit Timed out waiting for low
	rjmp	fail

fail07:	ldi	r16,FAULT07	; 1-bit low came too soon
	rjmp	fail

jdbit1:	rcall	getlo		; Wait for transition to low
	breq	1f		; Branch if we got low
	rcall	tcompr
	brcs	fail06		; Fail: timed out
	ret

1:	rcall	thalf
	brcc	fail07		; Transition too soon (fail)
	ldi	r16,SDBIT1B	; Wait out 2nd half
	rjmp	rchstate

;---------------------------------------------------------------------
; Wait out 2nd half of 1-bit (while level low)
;---------------------------------------------------------------------

fail08:	ldi	r16,FAULT08	; 1-bit low to high too soon
	rjmp	fail

jdbit1b: rcall	gethi		; Wait for a transition to high
	breq	2f		; Branch if line gone high
	rcall	wtime
	brcs	3f		; Expiry of time T
	ret

2:	rcall	thalf		; Check time to transition
	brcc	fail08		; Fail if transition occurred too soon
3:	set			; T=1
	rjmp	dfin

;---------------------------------------------------------------------
; Wait until line = High
;---------------------------------------------------------------------

jwaith:	rcall	gethi		; Check if stable line high
	breq	1f
	ret			; Stay in current state

1:	ldi	r16,SREADY
	rjmp	rchstate	; State = SREADY

;---------------------------------------------------------------------
; Data word received:
;  datah lower 4 bits has digit (data byte)
;---------------------------------------------------------------------

jrx:	mov	ZL,datah
	andi	ZL,0x0F		; Mask out lower 4 bits (digit #)
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
chstate: mov	rxstate,r16	; Change to state in r16
	ret

jfault:	ret

;---------------------------------------------------------------------
; State Jump Table
;---------------------------------------------------------------------

jmptab:	rjmp	jready		; 0 : Ready
	rjmp	j1st0		; 1 : Time low during 1st 0-bit
	rjmp	j1st0b		; 2 : Wait for high to low
	rjmp	jdbit		; 5 : Wait for data bit to stabilize
	rjmp	jdbit0		; 6 : Wait for first half of zero bit
	rjmp	jdbit0b		; 7 : Wait for 2nd half of zero bit
	rjmp	jdbit1		; 8 : Wait for first half of one bit
	rjmp	jdbit1b		; 9 : Wait for 2nd half of one bit
	rjmp	jrx		; 10 : Received data
	rjmp	jwaith		; 11 : Wait until signal = High
	rjmp	jfault		; 12 : Signal Fault

;---------------------------------------------------------------------
; Timer 0 ISR Routine
;---------------------------------------------------------------------

TIM0_COMPA_vect:

	push	r16		; r16
	in	r16,SREG	; 
	push	r16		; SREG
	push	r17		; r17

	lsl	mdin		; Shift in 1 more signal input sample
	sbic	IPORTX,MCHDIN	; Skip if input low
	inc	mdin

	lds	r16,fault	; Don't change counter if faulted
	andi	r16,0xF0
	cpi	r16,0xF0
	breq	rfault		; Jump to display fault

	inc	counterl	; Normally, we increment our tick
	brne	2f		;  counter
	inc	counterh

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
; Report the details of the signal fault
;---------------------------------------------------------------------

rfault:	sbi	PORTX,FLED	; Turn on the Fault LED
	sts	byte0,rxtimeh	; Receive timer high byte
	sts	byte1,rxtimel	; Receive timer low byte
	sts	byte2,counterh	; ISR counter high byte
	sts	byte3,counterl	; ISR counter low byte
	sts	byte4,datah	; Data high byte
	sts	byte5,datal	; Data low byte
	sts	byte6,bcount	; Bits remaining to be received
	lds	r16,fault	; Fault code
	sts	byte7,r16	;   displayed as byte 7
	rjmp	8b

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

udisp:	ldi	YL,lo8(byte0)
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

;---------------------------------------------------------------------
; Machester Receiver Initialization
;---------------------------------------------------------------------

	cbi	DDRX,MCHDIN	; Configure this pin as input
	sbi	PORTX,MCHDIN	; Configure this pin with pullup

	clr	rxtimel
	clr	rxtimeh		; T = 0 (no timings done yet)
	clr	counterl
	clr	counterh	; Counter = 0

	clr	mdin
	sbic	PINB,MCHDIN	; Test input line level
	inc	mdin		; Set to 1 if MCHDIN = high

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
;	r3	rxtimer+1
;	r4	(rxtimer+2)
;	r5	counter		counterl
;	r6	counter+1	counterh
;	r7	(counter+2)
;	r8	rxtimet		rxtimel
;	r9	rxtimet+1	rxtimeh
;	r10					udisp
;	r11	mdin
;	r12	ldata
;	r13	hdata
;	r14	bcount
;	r15				
;	
;	r16	ARG1				udisp
;	r17	ARG2				udisp
;	r18	
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
; When the Fault LED Comes on:
;	
;     This happens when the input signal is:
; 
;     1) Too fast or too slow 
;     2) Irregular in timing
;     3) Not a biphase Manchester encoded signal
; 
; To diagnose the problem, the Fault LED indicates that the
; display is reporting fault information. The 8x8 matrix,
; displays bytes from  top to bottom as follows:
; 
; Display Lines:
; 
;     0) rxtime high byte
;     1) rxtime low byte
;     2) counter high byte
;     3) counter low byte
;     4) high data byte (received so far)
;     5) low data byte
;     6) Bits remaining to be received
;     7) Fault Code 0xFx, where x is the code
;
; This is cleared by a RESET.
;
; Signal Format and Fault Codes:
;	
; ----/idle-high/-----+       +------/------+      +--/1/->
;                     |       |             |      |
;                     +-------+             +------+--/0/->
;   Time rxtime       |<----->|
;   Zero Bit          |<-----(0)---->|
;   One Bit                          |<----(1)---->|
;                       F1-^   F3-^
;                          F4-^     ^-F5 (when followed byte a high-low transition here)
;                                       F7-^  ^-F6 (when low transition fails to arrive on time)
;                                                  ^-F8
;	                   
;---------------------------------------------------------------------
; End 8x8rx.S
;---------------------------------------------------------------------
