;---------------------------------------------------------------------
; SlaveI2C.S : I2C Slave Framework for ATtiny13
; Warren Gay  Fri Feb 20 20:27:21 2015
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list

I2CINP	= PINB
I2COUT	= PORTB
I2CDDR	= DDRB
I2CSDA	= PB0
I2CSCL	= PB1
I2CMASK	= (1<<I2CSDA|1<<I2CSCL)
I2CRW	= 0				; Bit 0 is R=1/W=0

	.text
	.global	main,i2caddr,i2crequ

	.section .bss

i2caddr: .fill	1			; I2C Address
i2crequ: .fill	1			; Request address and R/W bit

	.text

;---------------------------------------------------------------------
; Initialize the ports for I2C
;---------------------------------------------------------------------

i2cinit:
	cbi	I2CDDR,I2CSDA		; Configure SDA as input
	cbi	I2CDDR,I2CSCL		; Configure SCL input
;	sbi	I2COUT,I2CSDA		; Enable (weak) pullup for SDA
;	sbi	I2COUT,I2CSCL		; Enable (weak) pullup for SCL
	cbi	I2COUT,I2CSDA		; Disable (weak) pullup for SDA
	cbi	I2COUT,I2CSCL		; Disable (weak) pullup for SCL
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
	cp	r24,I2CMASK		; Both change?
	breq	rbit			; If so, then start over
;
	bst	r0,I2CSDA		; T=SDA
	ret				; Consult r24.I2CSCL & T
	
;---------------------------------------------------------------------
; Write a bit to master: Master controls SCL
; r25.7 is written out
;---------------------------------------------------------------------

wbit:	sbic	I2CINP,I2CSCL		; Loop until
	rjmp	wbit			;  SCL=0
	sbrs	r25,7			; r25.7?
	sbi	I2CDDR,I2CSDA		; Apply SDA to bus (data bit=0)
2:	sbis	I2CINP,I2CSCL		; Loop until
	rjmp	2b			;  SCL=1
3:	sbic	I2CINP,I2CSCL		; Loop until
	rjmp	3b			;  SCL=0 again
	sbrs	r25,7			; Skip over if bit=1
	cbi	I2CDDR,I2CSDA		; Release SDA from bus
	ret

;---------------------------------------------------------------------
; Write byte in r25
;---------------------------------------------------------------------

wbyte:	sbic	I2COUT,I2CSDA		; Check internal SDA state..
	sbi	I2CINP,I2CSDA		; ..toggle SDA=0 (not yet on bus)
	ldi	r26,8			; Writing 8 data bits
;
1:	rcall	wbit			; Write 1 bit
	rol	r25
	dec	r26
	brne	1b			; Until all 8 bits written
;
	sbic	I2COUT,I2CSCL		; This procedure to avoid glitching
	sbi	I2CINP,I2CSCL		; Toggle SCL=0 (not yet on the bus)
	sbi	I2CDDR,I2CSCL		; Assert SCL=0 on bus (hold)
	ret

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
	lsl	r1			; Make room for new data bit
	bld	r1,0			; r1.0 = T (data bit)
	dec	r25			; One less bit
	brne	1b			; Loop until all 8 bits read
;
	clc				; Read successful
	ret				; C=0 Read ok, else T=1=Start/0=Stop
;
2:	sec				; C=1 failed read:
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
1:	rcall	rbit			; Wait for start bit
	sbrc	r24,I2CSCL		; Start/Stop received?
	rjmp	1b			; Loop until Start/Stop bit
;
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
	sbic	I2COUT,I2CSCL		; Check internal SCL state..
	sbi	I2CINP,I2CSCL		; toggle SCL=0 (not yet on the bus)
	sbi	I2CDDR,I2CSCL		; Hold SCL=0 on bus until we ACK/NAK
	ret

;---------------------------------------------------------------------
; Respond with ACK/NAK
;---------------------------------------------------------------------

ack:	sbic	I2COUT,I2CSDA		; Check internal state of SDA=0
	sbi	I2CINP,I2CSDA		; ..toggle SDA=0 internally (not yet on bus)
	sbi	I2CDDR,I2CSDA		; SDA=0 on bus

nak:	cbi	I2CDDR,I2CSCL		; Release SCL hold on bus

2:	sbis	I2CINP,I2CSCL		; Loop until
	rjmp	2b			;  SCL=1 (master)
3:	sbic	I2CINP,I2CSCL		; Loop until
	rjmp	3b			;  SCL=0
	nop
	cbi	I2CDDR,I2CSDA		; Release SDA from bus (if asserted)
	ret

;---------------------------------------------------------------------
; SlaveI2C Main Program
;---------------------------------------------------------------------

main:	cli
	ldi     r16,0b10000000
	ldi     r17,0b00000000  	; Select "full speed" for ATtiny13
	out     CLKPR,r16       	; Start clock prescale change      
	out     CLKPR,r17       	; Set clock prescale
	sei
;
	rcall	i2cinit
	clr	r1
	rcall	svc_init		; Initialize app and get slave address
	sts	i2caddr,r24		; Save returned slave address

;---------------------------------------------------------------------
; Main I2C Slave loop
;---------------------------------------------------------------------

mloop:	rcall	i2cslave		; Wait for start bit
	sts	i2crequ,r24		; Save request address & R/W bit
;
	clr	r1			; for gcc
	rcall	svc_start		; Call user with req info (arg1 = addr+RW)
	sbrc	r24,0			; Continue if r24.0 = 1 else nak and reset
	rjmp	2f			; Jump to service request
	rcall	nak			; Tell master NAK
	rjmp	mloop			;  and restart loop
;
;	Service Read/Write Request
;
2:	lds	r24,i2crequ		; Fetch request byte
	sbrc	r24,I2CRW		; R/W?
	rjmp	4f			; jmp to service master read req if I2CRW bit = 1
;
;	Service write request (read master's byte)
;
3:	rcall	ack			; else ACK master's write request
5:	rcall	rbyte			; r1=byte if C=0; else Start/Stop (T)
	brcs	666f			; When C=1, do error recovery
	sbic	I2COUT,I2CSCL		; Check internal SCL status
	sbi	I2CINP,I2CSCL		; ..toggle internal SCL=0 (not yet on bus)
	sbi	I2CDDR,I2CSCL		; SCL=0 (on bus now) to hold ACK/NAK for now..
;
	clr	r1			; for gcc
	mov	r24,r1			; Arg 1 = data byte received
	rcall	svc_write		; Service write request
	sbrc	r24,0			; Skip if r24.0=0
	rjmp	3b			; Else repeat with ACK if r24.0=1
;
7:	rcall	nak			; Reply with NAK
	rjmp	666f			;  and signal end
;
;	Service Master Read Requests
;
4:	clr	r1			; gcc insists on this being zero
	rcall	svc_read		; r24=ACK/NAK, r25=data
	sbrs	r24,0
	rjmp	44f			; Jump if svc_read says NAK
	rcall	ack			; ACK master's read request / prior byte
	rcall	wbyte			; Write data in r25
	rjmp	4b			; Loop and send another

44:	rcall	nak			; else NAK to master
;
;	Signal to app the ending
;
666:	clr	r1			; for gcc
	rcall	svc_end			; Let app know that it ended/failed
	rjmp	mloop			; Go wait for next request

;---------------------------------------------------------------------
; End testmain.S
;---------------------------------------------------------------------
