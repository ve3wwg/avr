;---------------------------------------------------------------------
; Test program for bit-banged i2c on ATtiny
; Warren Gay  Fri Feb 20 20:27:21 2015
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

LED	= PB4
I2CINP	= PINB
I2COUT	= PORTB
I2CDDR	= DDRB
I2CSDA	= PB0
I2CSCL	= PB1
I2CMASK	= (1<<I2CSDA|1<<I2CSCL)
I2CRW	= 0				; Bit 0 is R=1/W=0

	.text
	.global	main
	.section .bss
i2caddr: .fill	1			; I2C Address
i2crequ: .fill	1			; Request address and R/W bit

	.text
;
;	Called at initialization
;
svc_init:
	ret

;
;	Called when a request arrives
;
svc_start:
	ldi	r24,1
	ret
;
;	Service request
;
svc_req:
	ldi	r24,1
	ret
;
;	Error cleanup for current request
;
svc_err:
	ret

	.text

;---------------------------------------------------------------------
; Initialize the ports for I2C
;---------------------------------------------------------------------

i2cinit:
	cbi	I2CDDR,I2CSDA		; Configure SDA as input
	cbi	I2CDDR,I2CSCL		; Configure SCL input
	sbi	I2COUT,I2CSDA		; Enable (weak) pullup for SDA
	sbi	I2COUT,I2CSCL		; Enable (weak) pullup for SCL
	ret

;---------------------------------------------------------------------
; Wait for a bit:
;
; RETURNS:	r24.I2CSCL=1:	T=Data bit
;		r24.I2CSCL=0:	T=1=Start, T=0=Stop
;---------------------------------------------------------------------

rbit:	sbic	I2CINP,I2CSCL
	rjmp	rbit			; Loop until SCL=0
;
0:	in	r0,I2CINP		; Read SDA + SCL
	sbrs	r0,I2CSCL		; Skip if SCL=1
	rjmp	0b			; else loop back until SCL=1 or SDA changes
;
1:	in	r24,I2CINP		; Read SDA + SCL
	eor	r24,r0			; xor orig SDA + SCL
	andi	r24,I2CMASK		; Isolate SCL + SDA change bits
	breq	1b			; Loop until a change occurs
;
	bst	r0,I2CSDA		; T=SDA
	ret				; Consult r24.I2CSCL & T
	
;---------------------------------------------------------------------
; Read 8 bits into r1
;
; RETURNS:	C=0, read 8 bits into r1
;		C=1, T=1 is start bit, else T=0 for stop bit
;---------------------------------------------------------------------

rbyte:	clr	r1			; r1=0: accumulator for data
	ldi	r25,8			; Read 8 bits
;
1:	rcall	rbit			; Read 1 bit
	sbrs	r24,I2CSCL		; Normal data bit? (SCL=0?)
	rjmp	2f			; rjmp if Start/Stop (SCL=0)
;
	sbi	PINB,PB2
	lsl	r1			; Make room for new data bit
	bld	r1,0			; r1.0 = T (data bit)
	dec	r25			; One less bit
	brne	1b			; Loop until all 8 bits read
;
	clc				; Read successful
	ret				; C=0 Read ok, else T=1=Start/0=Stop
;
2:	sec				; C=1 failed read:
	sbi	PINB,PB3
	ret				; T=1 is Start bit, else Stop bit

;---------------------------------------------------------------------
; Start Slave Mode:
;
; ARGUMENTS:
;	1: r24	uint8_t		slave address
; RETURNS:
;	r24			received slave address + R/W bit
; NOTES:
;	Does not return until a start byte is successfully 
;	received.
;---------------------------------------------------------------------
i2cslave:
	sts	i2caddr,r24		; Save I2C address
1:	rcall	rbit			; Wait for start bit
	sbi	PINB,LED
	sbrc	r24,I2CSCL		; Start/Stop received?
	rjmp	1b			; Loop until Start/Stop bit
;
	sbi	PINB,LED
	rcall	rbyte
	brcs	1b			; Loop back if read failed
;
;	See if message directed at us: r1 holds address and R/W bit	
;
	mov	r24,r1			; Address + R/W bit
	andi	r24,0xFE		; Mask out R/W bit
	lds	r25,i2caddr		; Our slave address
	cp	r24,r25			; Compare addresses
	brne	1b			; Loop back if not our address
;
	mov	r24,r1			; Return r24 = slave address + R/W bit
	ret

;---------------------------------------------------------------------
; Respond with ACK/NAK
;---------------------------------------------------------------------

ack:	cbi	I2COUT,I2CSDA		; SDA=0
	sbi	I2CDDR,I2CSDA		; SDA=0 on bus
nak:	cbi	I2CDDR,I2CSCL		; Release SCL hold on bus
2:	sbis	I2CINP,I2CSCL
	rjmp	2b			; Loop until SCL=1 (master)
3:	sbic	I2CINP,I2CSCL
	rjmp	3b			; Loop until SCL=0
	nop
	cbi	I2CDDR,I2CSDA		; Release SDA from bus (if asserted)
	ret

;---------------------------------------------------------------------
; Main Program
;---------------------------------------------------------------------

main:	cli
	ldi     r16,0b10000000
	ldi     r17,0b00000000  	; Select "full speed" for ATtiny13
	out     CLKPR,r16       	; Start clock prescale change      
	out     CLKPR,r17       	; Set clock prescale
	sei

	rcall	i2cinit
	sbi	DDRB,LED		; LED = output
	cbi	PORTB,LED		; LED off
;
	sbi	DDRB,PB2		; PB2 = output
	sbi	DDRB,PB3		; PB3 = output

	rcall	svc_init

mloop:	cbi	PORTB,LED
	sbi	PORTB,LED
	cbi	PORTB,LED
;
	ldi	r24,0x68		; Slave addres == 0x68
	rcall	i2cslave		; Wait for start bit
	sts	i2crequ,r24		; Save request address & R/W bit
	rcall	svc_start		; Call user with start req info
	sbrc	r24,0			; Continue if r24.0 = 1 else nak and reset
	rjmp	2f			; Jump to service request
;
	rcall	nak			; Tell master NAK
	rjmp	8f			;  and reset
;
;	Service Read/Write Request
;
2:	rcall	ack			; ack initial request
	lds	r24,i2crequ		
	sbrc	r24,I2CRW		; R/W?
	rjmp	4f			; jmp to service master read req if I2CRW bit = 1
;
;	Service write request (read master's byte)
;
5:	rcall	rbyte			; r1=byte if C=0; else Start/Stop (T)
	brcs	666f			; When C=1, do error recovery
	cbi	I2COUT,I2CSCL		; SCL=0 (not on bus yet)
	sbi	I2CDDR,I2CSCL		; SCL=0 (on bus now) to hold ACK/NAK for now..
;
	mov	r24,r1			; Arg 1 = data byte received
	rcall	svc_req			; Service write request
	sbrs	r24,0			; Continue? 
	rjmp	7f			; r24.0=0, so go end writes
;
	sbi	PORTB,LED
	sbi	PORTB,PB2
	sbi	PORTB,PB3
	cbi	PORTB,LED
	cbi	PORTB,PB2
	cbi	PORTB,PB3
	rcall	ack			; ACK read byte
	rjmp	5b			; Repeat until master stops
;
;	End write sequence
;
7:	rcall	nak
	rjmp	9f
;
;	Service Master Read Requests
;
4:	rcall	nak
	rjmp	8f			; Not yet supported
;
;	Invoke user error routine
;
666:	rcall	svc_err			; Let user know that it failed
;
;	Eroneous end
;
8:	cbi	PORTB,LED
	sbi	PORTB,LED
	cbi	PORTB,LED
	sbi	PORTB,LED
	rjmp	mloop			; Go wait for next request
;
;	Successful end
;
9:	cbi	PORTB,LED
	cbi	DDRB,PB2
	cbi	DDRB,PB3
	rjmp	mloop

;---------------------------------------------------------------------
; End testmain.S
;---------------------------------------------------------------------
