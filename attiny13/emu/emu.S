#define __SFR_OFFSET 0 
#include <avr/io.h>

	.section .text
	.global	main

	.equ	c,0
	.equ	z,1
	.equ	n,2
	.equ	v,3
	.equ	s,4
	.equ	h,5
	.equ	t,6
	.equ	i,7
	.equ	sreg,63

	rjmp	test1
	rjmp	ext_int0
	rjmp	pcint0
	rjmp	tim0_ovf
	rjmp	ee_rdy
	rjmp	ana_comp
	rjmp	tim0_compa
	rjmp	tim0_compb
	rjmp	watchdog
	rjmp	adc
;
;	Test clear flags and branch if clear
;
test1:	clc		; Test 1 - clear flags and branch if clear
	brcc	1f
	break		; fail
;
1:	clh
	brhc	1f
	break		; fail
;
1:	cli
	brid	1f
	break		; fail
;
1:	cln
	brpl	1f
	break		; fail
;
1:	cls
	brge	1f
	break		; fail
;
1:	clt
	brtc	1f
	break		; fail
;
1:	clv
	brvc	1f
	break		; fail
;
1:	clz
	brne	2f
	break		; fail
;
2:	lds	16,sreg
	cpi	16,0x00
	breq	test2
	break		; fail
;
;	Test set flag and branch if set
;
test2:	sec		; Test 1 - clear flags and branch if clear
	brcs	1f
	break		; fail
;
1:	seh
	brhs	1f
	break		; fail
;
1:	sei
	brie	1f
	break		; fail
;
1:	sen
	brmi	1f
	break		; fail
;
1:	ses
	brlt	1f
	break		; fail
;
1:	set
	brts	1f
	break		; fail
;
1:	sev
	brvs	1f
	break		; fail
;
1:	sez
	breq	2f
	break		; fail
;
2:	lds	16,sreg
	cpi	16,0xFF
	breq	3f
	break		; fail
;
3:	cli
	brid	4f
	break		; fail
;
4:	clt
	rjmp	test3
;
;	Test LDI, CPI
;
test3:	ldi	16,0xEE
	cpi	16,0xEE
	breq	1f
	break			; Fail
;
1:	ldi	17,0xFF
	cpi	17,0xFF
	breq	2f
	break;
;
2:	ldi	18,0x01
	cpi	18,0x01
	breq	3f
	break;
;
3:	ldi	19,0x02
	cpi	19,0x02
	breq	4f
	break
;
4:	ldi	20,0x03
	cpi	20,0x03
	breq	5f
	break
;
5:	ldi	21,0x04
	cpi	21,0x04
	breq	6f
	break
;
6:	ldi	22,0x05
	cpi	22,0x05
	breq	7f
	break
;
7:	ldi	23,0x06
	cpi	23,0x06
	breq	8f
	break;
;
8:	ldi	24,0x07
	cpi	24,0x07
	breq	8f
	break;
;
8:	ldi	25,0x08
	cpi	25,0x08
	breq	8f
	break;
;
8:	ldi	26,0x09
	cpi	26,0x09
	breq	8f
	break;
;
8:	ldi	27,0x10
	cpi	27,0x10
	breq	8f
	break;
;
8:	ldi	28,0x11
	cpi	28,0x11
	breq	8f
	break;
;
8:	ldi	29,0x12
	cpi	29,0x12
	breq	8f
	break;
;
8:	ldi	30,0x13
	cpi	30,0x13
	breq	8f
	break;
;
8:	ldi	31,0x14
	cpi	31,0x14
	breq	test4
	break;
;
;	Test4 - NOP
;
test4:	lds     16,sreg
	nop
	lds	17,sreg
	cp	16,17
	breq	2f
	break		; fail
;
;	Tests that CPSE agrees with above test
;
2:	cpse	16,17
	break		; fail
;
;	Test 5 - Test CPC
;
test5:	eor	0,0	; r0 = 0
	eor	1,1	; r1 = 0
	cpse	0,1
	break		; fail
2:	clc
	cpc	0,1	; C=0, so should still compare EQ
	breq	2f
	break		; fail
2:	sec		; C=1, so now should be NE
	cpc	0,1
	brne	2f
	break		; fail
2:	inc	0	; r0 = 1
	sec		; C=1
	cpc	0,1	; r0 = 1, r1 = 0 + C=1, should EQ
	breq	test6
	break		; fail
;
;	Test 6 - Increment
;
test6:	eor	0,0
1:	inc	0
	brne	1b
2:	dec	0
	brne	2b
;
;	SWAP
;
test7:	ldi	19,0xFC
	swap	19
	cpi	19,0xCF
	breq	2f
	break		; Fail
2:	tst	19
	brmi	2f
	break		; Fail
2:	brne	2f
	break		; Fail
2:	ldi	20,0
	tst	20
	breq	2f
	break		; Fail
2:	
;
;	MOV/ADD/ADC
;
test8:	ldi	16,1
	ldi	17,2
	mov	18,16
	sec
	add	18,17
	cpi	18,3
	breq	2f
	break		; Fail
2:	mov	18,16
	sec
	adc	18,17
	cpi	18,4
	breq	2f
	break		; Fail
2:	ldi	16,0xFF
	ldi	17,1
	add	16,17
	brcs	2f
	break		; Fail
	breq	2f
	break		; Fail
2:	ldi	25,1
	ldi	24,5
	adiw	24,3
	cpi	24,8
	breq	2f
	break		; Fail
	cpi	25,1
	breq	2f
	break		; Fail
2:
;
end:	break
	rjmp	8b

ext_int0:
pcint0:
tim0_ovf:
ee_rdy:
ana_comp:
tim0_compa:
tim0_compb:
watchdog:
adc:
	rjmp	ext_int0
