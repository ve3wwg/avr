;---------------------------------------------------------------------
; Example 3 : Interrupt driven Analog to Digital Conversion
;
; Warren W. Gay VE3WWG	Sat Oct 25 11:59:53 2014
; GPL v2 License (See file LICENSE)
;
; This example program configures:
;
;   PB3..0  as LED outputs 3..0
;   PB4     as ADC in (ADC2)
;
; The middle wiper arm of the 10k potentiometer is wired to PB4.
; The other ends of the pot are connected to +Vcc and Gnd, causing
; the pot to act as a voltage divider.
;
; OPERATION:
;
; This example uses an interrupt service routine to take the result
; of an ADC conversion, placing MSB 4-bits of the conversion into
; a static RAM location named ADC4b. After depositing the ADC
; value, the flag in bit 0 of SRAM location ADC4f is set to 1, to
; signal to the main routine that a new ADC value has been stored.
;
; The main program performs the initial configuration of the ADC
; peripheral, and then enters the main loop. The main loop simply
; loops until the flag is set in ADC4f. Once the flag has been 
; found set, it then picks up the 4-bit ADC value in ADC4b and
; displays it in the LED outputs. The ADC4f flag is cleared, so
; that the main loop will not update the LEDs again, until the
; interrupt service routine has deposited a new value.
;
; This program demonstrates how to:
;
; 1. Configure the ADC for interrupt operation
; 2. How to service an ADC interrupt
; 3. Poll SRAM location for ISR updates
; 4. Act on new ISR deposited information
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 		/* Avoid _SFR_IO() macro */
	.nolist
#include <avr/io.h>
	.list

;
;	SRAM storage for ADC data and flag
;
	.data
ADC4b:	.byte	0		; Where 4-bits of ADC status are stored
ADC4f:	.byte	0		; Bit 0 set when data is new

	.text
	.global	main, ADC_vect
;
;	ADC Interrupt Service Routine
;
ADC_vect:
	push	r16		; Save r16
	in	r16,SREG	; r16 = status indicators
	push	r16		; Save status indicators
	push	r17
;
;	Read ADC Value
;
	in	r16,ADCL	; Read low order bits (8-bits)
	in	r17,ADCH	; Read high order bits (2-bits)
;
;	Shift result right 6 bits (leaving 4 rightmost)
;
	lsr	r17
	ror	r16		; r1:r0 Shifted 1
	lsr	r17
	ror	r16		; r1:r0 Shifted 2
	lsr	r16		; r0 Shifted 3
	lsr	r16		; r0 Shifted 4
	lsr	r16		; r0 Shifted 5
	lsr	r16		; r0 Shifted 6 bits right
;
;	Save into ADC4b and set flag in ADC4f
;
	sts	ADC4b,r16	; Save MSB 4-bits of ADC 
	ldi	r16,0x01	; Set flag
	sts	ADC4f,r16	;  in ADC4f

	pop	r17
	pop	r16		; Restore status indicators
	out	SREG,r16	; SREG restored
	pop	r16
	reti

;
;	Main Program
;
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
	cbi	ADMUX,0		; 1:0 = 10 selects ADC2 (PB4)
	cbi	ADCSRA,ADATE	; ADATE=0 auto trigger off
	cbi	ADCSRA,ADPS2	; ADPS2=0
	cbi	ADCSRA,ADPS1	; ADPS1=0
	cbi	ADCSRA,ADPS0	; ADPS0=0, ADPS2..0 = 000 div by 2
	sbi	DIDR0,ADC2D	; Disable digital input on ADC2 (PB4)
	cbi	ADCSRB,ADTS2
	cbi	ADCSRB,ADTS1
	cbi	ADCSRB,ADTS0	; ADTS2..0 = 000 = Free running mode
	sbi	ADCSRA,ADATE	; ADATE=1, auto trigger on (free running mode)
	sei
	sbi	ADCSRA,ADIE	; ADIE=1 interrupts on
	sbi	ADCSRA,ADSC	; Start First ADC Conversion
;
;	Main loop
;
1:	lds	r16,ADC4f	; Test flag in ADC4f.0
	andi	r16,0x01	; Mask out bit 0
	breq	1b		; Loop back, if bit=0
;
;	Read deposited 4-bit ADC Result
;
	lds	r16,ADC4b	; Load saved ADC value (4-bits)
	clr	r17
	sts	ADC4f,r17	; Clear flag (mark as processed)
;
;	Output bits to LEDs
;
	out	PORTB,r16	; Display ADC value
	rjmp	1b		; Start next conversion

;---------------------------------------------------------------------
; End example3.S
;---------------------------------------------------------------------
