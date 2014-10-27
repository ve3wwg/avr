;---------------------------------------------------------------------
; Example 5 : Timer triggered, interrupt driven ADC, with watchdog
;
; Warren W. Gay VE3WWG	Mon Oct 27 20:51:33 2014
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
; DESCRIPTION:
;
; Example 5 ads a watchdog facility to example 4. The watchdog timer
; is configured for a 4 second timeout. When it times out, an interrupt
; occurs causing the ISR to turn on all LEDs as a warning for the 
; pending reset (if the control does not change in the next 4
; seconds- all LEDs on indicates that the watchdog interrupt has
; occurred). This is stage one.
; 
; If no change occurs in the _next_ 4 seconds, the LEDs will blink
; off momentarily indicating that the MCU went through a device
; reset (stage two).
; 
; If the ptentiometer is changed within the 4 second timeout period,
; the watchdog timer is reset using the use of the wdr instruction.
; As long as the control keeps changing, no MCU reset occurs.
;
; This example uses a two-stage watchdog reset:
; 
; 1) Initial timeout: Interrupts through WDT_vect (lights all LEDs)
; 2) 2nd timeout: Resets the MCU
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 		/* Avoid _SFR_IO() macro */
	.nolist
#include <avr/io.h>
	.list

COUNT	 = 105			; Set timer/counter0 count
PRESCALE = 5			; 5 == CLKio / 1024

;
;	SRAM storage for ADC data and flag
;
	.data
ADC4b:	.byte	0		; Where 4-bits of ADC status are stored
ADC4f:	.byte	0		; Bit 0 set when data is new
lastb:	.byte	0		; Last known value of ADC

	.text
	.global	main, TIM0_COMPA_vect, ADC_vect, WDT_vect
;
;	Watchdog timer interrupt
;
WDT_vect:
	sbi	PORTB,PB3	; Light LEDs..
	sbi	PORTB,PB2
	sbi	PORTB,PB1
	sbi	PORTB,PB0
	reti             	; Stage 2 now in effect       

;
;	Timer/Counter0 Interrupt Service Routine
;
TIM0_COMPA_vect:
	reti			; We don't need to do anything here

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
	clr	r1
	out	PORTB,r1	; All LEDs off initially

	ldi	r16,0xFF
	sts	lastb,r16	; lastb = 0xFF (forces first not equal comapare)
	sts	ADC4b,r1	; Clear reading 
	sts	ADC4f,r1	; Clear flag
;
;	Configure the Watchdog timer
;
	cli
	wdr			; Watchdog reset

	in	r16,WDTCR	; Read flags in WDTCR
	ori	r16,_BV(WDCE)|_BV(WDE)
	out	WDTCR,r16
;
;	Have only 4 cycles to write to WDTCR now..
;	Activate Interrupt + System mode (two stage watchdog)
;
	ldi	r16,_BV(WDE)|_BV(WDTIE)|_BV(WDP3) ; WDT = 4 seconds
	out	WDTCR,r16
;
;	Configure Timer/Counter 0
;
	clr	r1
	out	GTCCR,r1	; GTCCR.TSM=0 (which is normally the case)
	out	TCCR0B,r1	; Stop Timer/Counter0 (no clock source)
	ldi	r16,_BV(OCIE0B)|_BV(OCIE0A)|_BV(TOIE0)
	out	TIMSK0,r16	; Disable all timer 0 interrupts
	ldi	r16,_BV(OCF0B)|_BV(OCF0A)|_BV(TOV0)
	out	TIFR0,r16	; Clear any pending interrupts for timer0

	ldi	r16,COUNT
	out	OCR0A,r16       ; Set OCR0A
	out	TCNT0,r1	; Zero timer0 counter
	ldi	r16,_BV(WGM01)
	out	TCCR0A,r16	; Timer mode is CTC (WGM01:WGM00 = 10)
	ldi	r16,PRESCALE
	andi	r16,_BV(CS02)|_BV(CS01)|_BV(CS00) ; Leave WGM02=0
	out	TCCR0B,r16	; Choose the PRESCALE
	ldi	r16,_BV(OCIE0A)
	out	TIMSK0,r16	; Enable Timer/Counter0 Output Compare Match A
;
;	Configure ADC
;
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
	sbi	ADCSRB,ADTS1
	sbi	ADCSRB,ADTS0	; ADTS2..0 = 011 - Timer/Counter Compare Match A
	sbi	ADCSRA,ADATE	; ADATE=1, auto trigger on (Timer/Counter 0)
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
;	Compare with last known value
;
	lds	r17,lastb
	cp	r16,r17
	breq	1b		; If ADC value same, then loop back
;
;	The control has changed in value
;
	wdr			; Reset the watchdog timer
;
;	Output bits to LEDs
;
	sts	lastb,r16
	out	PORTB,r16	; Display ADC value
	rjmp	1b		; Start next conversion

;---------------------------------------------------------------------
; End example5.S
;---------------------------------------------------------------------
