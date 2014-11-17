;---------------------------------------------------------------------
; debrick13.S - Unbrick ATtiny*
; Warren W. Gay VE3WWG	Wed Oct 29 19:06:23 2014
;---------------------------------------------------------------------
;
; NOTE [1]: The delay routine timings in this program assume:
;
;   ATtiny2313A operating with:
;
;   1) internal RC oscillator, 
;   2) at approximately 8 MHz,
;   3) CKDIV8 (Clock divided by 8)
;
;   Thus operating at 1 MIPS
;
; CONNECTIONS:
;
;   8213A/PIN   DEVICE UNDER TEST
;   ---------   -----------------
;   PD0/2   -   DUT /RESET (DUT pin 1)
;   PD1/3   -   Serial Clock Input (DUT pin 2)
;   PD2/6   -   Serial Data In (DUT SDO pin)
;   PD3/7   -   Serial Instruction Input (DUT pin 6) 
;   PD4/8   -   Serial Data Input (DUT pin 5)
;   PD5/9   -   Vcc (DUT pin 8)
;
;   PB6/18  -   Device Switch (closed for ATtiny13A)
;   PB0/12  -   Start Button (grounded to start programming)
;   PB1/13  -   Done LED (grounded cathode)
;
;---------------------------------------------------------------------

#define __SFR_OFFSET 0	/* Avoid _SFR_IO() macro */
	.nolist
#include <avr/io.h>
	.list

	.text
	.global	main

HFUSE13	= 0xFF		; ATtiny13A
LFUSE13	= 0x6A

HFUSE	= 0xDF   	; ATtiny25/45/85
LFUSE	= 0x62   

DDRX	= DDRD
PORTX	= PORTD
PINX	= PIND

RST	= PD0		; Output to level shifter for !RESET from transistor to Pin 1
CLKOUT	= PD1		; Connect to Serial Clock Input (SCI) Pin 2
DATAIN	= PD2		; Connect to Serial Data Output (SDO) Pin 7
INSTOUT	= PD3		; Connect to Serial Instruction Input (SII) Pin 6
DATAOUT	= PD4		; Connect to Serial Data Input (SDI) Pin 5 
VCC	= PD5		; Connect to VCC Pin 8

DDRY	= DDRB
PORTY	= PORTB
PINY	= PINB

DSW     = PB6           ; Device switch: low = ATtiny13 else ATtiny25/45/85
PBUT    = PB0           ; Start PB: low = start
DLED	= PB1		; Done LED (Port B)

;
;	Write Instruction
;
write:	sbis	PINX,DATAIN	; Loop until DATAIN high
	rjmp	write
;
;	Write an initial zero bit
;
	cbi	PORTX,DATAOUT	; DATAOUT = low
	cbi	PORTX,INSTOUT	; INSTOUT = low
	sbi	PORTX,CLKOUT	; CLKOUT = high
	cbi	PORTX,CLKOUT	; CLKOUT = low
;
	ldi	r18,8		; 8 bits
;
;	Write Data Bit
;
1:	sbrc	r16,7		; Skip if r16.7 clear
	sbi	PORTX,DATAOUT	; SDI 1-bit
	sbrs	r16,7		; Skip if r16.7 set
	cbi	PORTX,DATAOUT	; SDI 0-bit
;
;	Write Instruction Bit
;
	sbrc	r17,7
	sbi	PORTX,INSTOUT	; SII 1-bit
	sbrs	r17,7
	cbi	PORTX,INSTOUT	; SII 0-bit
;
	lsl	r16		; Shift SDI left
	lsl	r17		; Shift SII left
;
;	Clock and repeat until 8 bits complete
;	
	sbi	PORTX,CLKOUT	; CLKOUT = high
	cbi	PORTX,CLKOUT	; CLKOUT = low
	dec	r18		; One less bit
	brne	1b
;
;	Complete write cycle with 2 x 0-bit
;
	cbi	PORTX,DATAOUT	; DATAOUT = low
	cbi	PORTX,INSTOUT	; INSTOUT = low
;
	sbi	PORTX,CLKOUT	; CLKOUT = high, 1st 0-bit
	cbi	PORTX,CLKOUT	; CLKOUT = low
;
	sbi	PORTX,CLKOUT	; CLKOUT = high, 2nd 0-bit
	cbi	PORTX,CLKOUT	; CLKOUT = low
	ret

;
;	Wait for SDO High
;
waitsdo: sbis	PINX,DATAIN	; Test SDO, and skip next if high
	rjmp	waitsdo		; else loop back
	ret			; SDO is high

;
;	Delay 10 us		See Note [1]
;
d10us:	nop			; rcall takes 3 + 1 for nop
	nop			; + 1
	nop			; + 1
	ret			; + 4 => ~ 10 usec

;
;	Delay 60 us		See Note [1]
;
d60us:	ldi	r17,4
4:	rcall	d10us
	dec	r17
	brne	4b
	ret

;
;	Delay 300 us		See Note [1]
;
d300us:	ldi	r18,5
5:	rcall	d60us
	dec	r18
	brne	5b
	ret

;
;	Main Program
;
main:	in	r16,MCUCR	; Read MCUCR
	andi	r16,0x7F	; PUD=0
	out	MCUCR,r16	; Make sure pullups are enabled

	sbi	DDRX,VCC	; Output -> VCC
	sbi	DDRX,RST	; Output -> RST (DUT PB5)
	sbi	DDRX,DATAOUT	; Output -> DATAOUT (SDI) - Serial Data Input
	sbi	DDRX,INSTOUT	; Output -> INSTOUT (SII/PB1) - Serial Instruction Input
	sbi	DDRX,CLKOUT	; Output -> CLKOUT (SCI/PB3) - Serial Clock Input
	sbi	DDRX,DATAIN	; Output (Initially) -> DATAIN (SDO/PB2) - Serial Data Output
;
	sbi	DDRY,DLED	; Output : DLED
	cbi	DDRY,DSW	; Input : Device switch
	sbi	PORTY,DSW	; Enable pullup for device switch
	cbi	DDRY,PBUT	; Input : Push button (start = low)
	sbi	PORTY,PBUT	; Enable pullup resistor for PBUT
	sbi	PORTX,RST	; RST = high, Level is inverted (12V off)
	cbi	PORTX,VCC	; VCC Power off
;
;	Ready for programming mode
;
redo:	cbi	PORTY,DLED	; DLED off
	cbi	PORTX,DATAOUT	; DATAOUT (SDI) = low
	cbi	PORTX,INSTOUT	; INSTOUT (SII) = low
	cbi	PORTX,DATAIN	; DATAIN (SDO) = low
;
;	Wait for start button
;
1:	sbic	PINY,PBUT	; Skip next if push button pushed (grounded)
	rjmp	1b		; Else loop until button pushed

;
;	Enter high voltage serial programming mode
;
	sbi	PORTX,VCC	; VCC on (High)
	rcall	d60us		; Wait for VCC to stabilize

	cbi	PORTX,RST	; RST = Low (turn on 12V)
	rcall	d10us		; Wait for Prog_enable signature to latch

	cbi	DDRX,DATAIN	; DATAIN = input (release SDO pin)
	sbi	PORTX,DATAIN	; Enable pullup on DATAIN
	rcall	d300us		; Wait time before any SDI/SII
;
;	WRITE NEW HFUSE
;
	ldi	r16,0x40	; Write Fuse High 1/5 SDI
	ldi	r17,0x4C	; 1/4 SII
	rcall	write

        ldi	r16,HFUSE	; Write Fuse High 2/5 SDI (ATtiny25/45/85)
	sbis	PINY,DSW	; Skip next if device switch open
	ldi	r16,HFUSE13	; HFUSE for ATtiny13
	ldi	r17,0x2C	; 2/4 SII
	rcall	write

        ldi	r16,0x00	; Write Fuse High 3/5 SDI
	ldi	r17,0x74	; 3/4 SII
	rcall	write

        ldi	r16,0x00	; Write Fuse High 4/5
	ldi	r17,0x7C	; 4/4 SII
	rcall	write

	rcall	waitsdo		; Wait until SDO is raised high

;
;	WRITE NEW LFUSE
;
        ldi	r16,0x40	; Write Fuse Low 1/4 SDI
	ldi	r17,0x4C	; 1/4 SII
	rcall	write

        ldi	r16,LFUSE	; Write Fuse Low 2/4 SDI (ATtiny15/45/85)
	sbis	PINX,DSW	; Skip next if device switch open
	ldi	r16,LFUSE13	; ATtiny13 LFUSE
	ldi	r17,0x2C	; 2/4 SII
	rcall	write

        ldi	r16,0x00	; Write Fuse Low 3/4 SDI
	ldi	r17,0x64	; 3/4 SII
	rcall	write

        ldi	r16,0x00	; Write Fuse Low 4/4 SDI
	ldi	r17,0x6C	; 4/4 SII
	rcall	write
	rcall	waitsdo		; Wait until SDO is raised high

;
;	PERFORM CHIP ERASE (UNDOES LOCK FUSES IN THE PROCESS)
;
	ldi	r16,0x80	; 1/3 SDI
	ldi	r17,0x4C	; 1/3 SII
	rcall	write

	ldi	r16,0x00	; 2/3 SDI
	ldi	r17,0x64	; 2/3 SII
	rcall	write

	ldi	r16,0x00	; 3/3 SDI
	ldi	r17,0x6C	; 3/3 SII
	rcall	write
	rcall	waitsdo		; Wait until SDO is raised high

;
;	Exit programming mode
;
	cbi	PORTX,CLKOUT	; CLKOUT = low
	rcall	d10us
	sbi	PORTX,RST	; 12V off
	rcall	d10us
	cbi	PORTX,VCC	; VCC = off (low)
;
;	Make DATAIN an Output again, and set it low
;
	sbi	DDRX,DATAIN	; Change back to output 
	cbi	PORTX,DATAIN	; Set DATAIN low
;
;	Light the "Done LED"
;
	sbi	PORTY,DLED
;
;	Delay about 10 seconds
;
	ldi	r20,130
	clr	r21
1:	rcall	d300us
	dec	r21
	brne	1b
	dec	r20
	brne	1b
;
	rjmp	redo

;---------------------------------------------------------------------
; End unbrick13.S
;---------------------------------------------------------------------
