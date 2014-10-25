;---------------------------------------------------------------------
; Example 1 : Analog to Digital Conversion
;
; Warren W. Gay VE3WWG	Sat Oct 25 11:59:53 2014
; GPL v2 License (See file LICENSE)
;
; This example program configures:
;
;   PB3..0  as LED outputs 3..0
;   PB4     as ADC in (ADC2)
;
; The program converts the analog signal on PB4 (ADC2) into a
; 10-bit value, then shifts it down to access the upper most
; significant 4 bits. These are then displayed on the LEDS in
; binary form (PB3 is 8's, PB2 4's, PB1 2's and PB0 is 1's column).
;
; The middle wiper arm of the 10k potentiometer is wired to PB4.
; The other ends of the pot are connected to +Vcc and Gnd, causing
; the pot to act as a voltage divider.
;
; This program demonstrates how to:
;
; 1. Configure the ADC for polled operation
; 2. Request the ADC conversion (sbi ADCSRA,ADSC)
; 3. Read the results from ADCL and ADCH
; 4. Shift and display the uppermost bits on the LEDs
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 		/* Avoid _SFR_IO() macro */
	.nolist
#include <avr/io.h>
	.list

	.text
	.global	main

main:	ldi	r16,_BV(PB3)|_BV(PB2)|_BV(PB1)|_BV(PB0)
	out	DDRB,r16	; PB3..PB0 is output, PB4 input
	cbi	PORTB,PB0	; Pullup on PB0 off
;
;	Configure ADC
;
	cli
	sbi	ADCSRA,ADEN	; Enable ADC
	cbi	ADMUX,REFS0	; REFS=0 to use Vcc reference (else internal ref)
	cbi	ADMUX,ADLAR	; ADLAR=0 right justified value
	sbi	ADMUX,1
	cbi	ADMUX,0		; 1:0 = 10 selects ADC2 on PB4
	cbi	ADCSRA,ADATE	; ADATE=0 auto trigger off
	cbi	ADCSRA,ADIE	; ADIE=0 interrupts off
	cbi	ADCSRA,ADPS2	; ADPS2=0
	cbi	ADCSRA,ADPS1	; ADPS1=0
	cbi	ADCSRA,ADPS0	; ADPS0=0, ADPS2..0 = 000 div by 2
	sbi	DIDR0,ADC2D	; Disable digital input on ADC2
	sei
;
;	Main loop
;
1:	sbi	ADCSRA,ADSC	; Start ADC Conversion
	sbis	ADCSRA,ADIF	; Skip next if ADSCRA.ADIF = 1
	rjmp	1b		; Loop until conversion complete
;
;	Read 10-bit ADC Result
;
	in	r0,ADCL		; Read low order bits (8-bits)
	in	r1,ADCH		; Read high order bits (2-bits)
;
;	Shift result right 6 bits (leaving 4 rightmost)
;
	lsr	r1
	ror	r0		; r1:r0 Shifted 1
	lsr	r1
	ror	r0		; r1:r0 Shifted 2
	lsr	r0		; r0 Shifted 3
	lsr	r0		; r0 Shifted 4
	lsr	r0		; r0 Shifted 5
	lsr	r0		; r0 Shifted 6 bits right
;
;	Output bits to LEDs
;
	out	PORTB,R0
	rjmp	1b		; Start next conversion

;---------------------------------------------------------------------
; End example1.S
;---------------------------------------------------------------------
