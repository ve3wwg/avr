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

I2CMASK	= BITSDA|BITSCL
BITSDA	= 1<<I2CSDA
BITSCL	= 1<<I2CSCL

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

i2cinit:sbi	I2CDDR,I2CSDA		; SDA as output..
	cbi	I2COUT,I2CSDA		; SDA=0
	cbi	I2CDDR,I2CSDA		; Now configure SDA as input
;	sbi	I2COUT,I2CSDA		; Enable (weak) SDA pullup
	cbi	I2COUT,I2CSDA
;
	sbi	I2CDDR,I2CSCL		; SCL as output..
	cbi	I2COUT,I2CSCL		; SCL=0
	cbi	I2CDDR,I2CSCL		; Now configure SCL as input
;	sbi	I2COUT,I2CSCL		; Enable (weak) SCL pullup
	cbi	I2COUT,I2CSCL
;
;	in	r24,MCUCR
;	ori	r24,1<<PUD
;	out	MCUCR,r24
	ret

;---------------------------------------------------------------------
; Wait for a start bit (only)
;---------------------------------------------------------------------

sbit:	in	r24,I2CINP
	andi	r24,I2CMASK
	cpi	r24,I2CMASK		; Loop
	brne	sbit			; ..until SCL=1 and SDA=1
;
1:	in	r24,I2CINP		; Read SDA + SCL
	andi	r24,I2CMASK		; Isolate SCL + SDA change bits
	cpi	r24,I2CMASK
	breq	1b			; Loop until a change occurs
;
	cpi	r24,BITSCL		; SDA=0 and SCL=1 if a start bit
	brne	sbit			; ..branch if something else
	ret				; Start bit has been sensed

;---------------------------------------------------------------------
; Wait for a data bit or start/stop bit
;
; RETURNS:	C=0, T=Data bit
;		C=1, aborted (start/stop bit received)
;---------------------------------------------------------------------

r0bit:	sbic	I2CINP,I2CSCL		; Loop
	rjmp	r0bit			; ..until SCL=0
rbit:	sbis	I2CINP,I2CSCL		; Loop
	rjmp	rbit			; ..until SCL=1
;
	in	r0,I2CINP		; r0 = Initial SDA + SCL
1:	in	r24,I2CINP		; Read SDA + SCL
	eor	r24,r0			; xor orig SDA + SCL
	andi	r24,I2CMASK		; Isolate SCL + SDA change bits
	breq	1b			; Loop until a change occurs
	cpi	r24,BITSCL		; Only SCL should change for data
	brne	9f			; Branch if failed
;
4:	bst	r0,I2CSDA		; T=SDA (data bit)
	clc				; Success: Data returned in T
	ret
9:	sec				; Start/Stop bit (fail)
	ret
	
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
	rcall	sbit			; Wait for start bit
;
;	Got a start bit, read address + R/W
;
	clr	r1			; r1=0: accumulator for data
	ldi	r25,8			; Read 8 bits
	rcall	r0bit			; First bit..
;
2:	brcs	i2cslave		; Branch if start/stop bit
;
;	Got data bit in T flag
;
	lsl	r1			; Make room for new data bit
	bld	r1,0			; r1.0 = T (data bit)
	dec	r25			; One less bit
	breq	3f			; Branch if done all 8 bits
	rcall	rbit			; Read next bit
	rjmp	2b
;
;	See if message directed at us: r1 holds address and R/W bit	
;
3:	mov	r24,r1			; Address + R/W bit
	andi	r24,0xFE		; Mask out R/W bit
	lds	r25,i2caddr		; Our slave address
	cp	r24,r25			; Compare addresses
	brne	i2cslave		; Loop back if not our address
;
	sbi	I2CDDR,I2CSCL		; Hold SCL=0 on bus until we ACK/NAK
	mov	r24,r1			; Return r24 = slave address + R/W bit
	ret

;---------------------------------------------------------------------
; Respond with ACK/NAK
;---------------------------------------------------------------------

ack:	sbi	I2CDDR,I2CSDA		; SDA=0 on bus
nak:	sbi	I2COUT,I2CSCL		; Set SCL=1 to avoid glitch
	cbi	I2CDDR,I2CSCL		; Release SCL hold on bus
	cbi	I2COUT,I2CSCL		; Set SCL=0 internally
2:	sbis	I2CINP,I2CSCL		; Loop until
	rjmp	2b			;  SCL=1 (master)
3:	sbic	I2CINP,I2CSCL		; Loop until
	rjmp	3b			;  SCL=0
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

	sbi	DDRB,PB2

;---------------------------------------------------------------------
; Main I2C Slave loop
;---------------------------------------------------------------------

	cbi	PORTB,PB2
	cbi	PORTB,PB3
	cbi	PORTB,PB4

mloop:	sbi	PINB,PB4
	rcall	i2cslave		; Read start bit + addr + R/W bit (r24)
contd:	sts	i2crequ,r24		; Save request address & R/W bit
	clr	r1			; for gcc
	rcall	svc_start		; Call user with req info (arg1 = addr+RW)
	sbrs	r24,0			; Skip next if r24.0=1
	rjmp	7f			; else go NAK

;---------------------------------------------------------------------
;	Service Master's Request
;---------------------------------------------------------------------

	lds	r24,i2crequ		; Fetch request byte
	sbrc	r24,I2CRW		; R/W?
	rjmp	400f			; jmp when r24.0 = 1 (read request)

;---------------------------------------------------------------------
;	Service write request (read master's byte)
;---------------------------------------------------------------------

300:	sbi	PINB,PB3		; TOGGLE
	rcall	ack			; else ACK master's write request
rbyte:	clr	r1			; r1=0: accumulator for data
	ldi	r25,8			; Read 8 bits
	rcall	r0bit			; Read 1st bit
;
1:	brcs	mloop			; Aborted: Start/Stop bit
	lsl	r1			; Make room for new data bit
	bld	r1,0			; r1.0 = T (data bit)
	dec	r25			; One less bit
	breq	2f
	rcall	rbit			; Read nth bit
	rjmp	1b
;
2:	sbi	I2CDDR,I2CSCL		; SCL=0 (on bus now) to hold ACK/NAK for now..
	clr	r1			; for gcc
	mov	r24,r1			; Arg 1 = data byte received
	rcall	svc_write		; Service write request
	sbrs	r24,0			; Skip if r24.0=0
	rjmp	300b			; Here r24.0=1, so ACK and repeat

;---------------------------------------------------------------------
;	End with a NAK
;---------------------------------------------------------------------

7:	sbi	PINB,PB3
	sbi	PINB,PB3
	rcall	nak			; Else reply with NAK
	rjmp	mloop			

8:	sbi	PINB,PB2
	sbi	PINB,PB2
	rjmp	7b

;---------------------------------------------------------------------
;	Service Master Read Requests
;---------------------------------------------------------------------

400:	clr	r1			; gcc insists on this being zero
	rcall	svc_read		; r24=ACK/NAK, r25=data
	sbrs	r24,0
	rjmp	8b			; R24.0=0, so NAK
;
	sbi	PINB,PB2
	rcall	ack			; ACK master's read request / prior byte
wbyte:	ldi	r26,8			; Writing 8 data bits
;
wbit:	sbic	I2CINP,I2CSCL		; Loop until
	rjmp	wbit			;  SCL=0
	sbrs	r25,7			; r25.7?
	sbi	I2CDDR,I2CSDA		; Apply SDA to bus (data bit r25.7=0)
2:	sbis	I2CINP,I2CSCL		; Loop until
	rjmp	2b			;  SCL=1
3:	sbic	I2CINP,I2CSCL		; Loop until
	rjmp	3b			;  SCL=0 again
	cbi	I2CDDR,I2CSDA		; Release SDA from bus
;
	rol	r25
	dec	r26
	brne	wbit			; Until all 8 bits written
;
;	Wait for Master to ACK/NAK
;
	rcall	rbit
	brcs	mloop			; Branch if start/stop bit
	brtc	400b			; Got ACK from master, repeat
	rjmp	mloop			; Else wait for new transaction

;---------------------------------------------------------------------
; End testmain.S
;---------------------------------------------------------------------
