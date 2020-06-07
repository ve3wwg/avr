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
	.equ	IO_Base,0x0020

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
;	AND
;
test9:	ldi	16,0xF5
	ldi	17,0x86
	and	16,17
	cpi	16,0x84
	breq	2f
	break		; Fail
2:	mov	0,16
	ldi	19,7
	and	0,19	
	ldi	20,4
	cp	0,20
	breq	2f
	break		; Fail
2:	ldi	16,0xF0
	and	0,16
	breq	2f
	break		; Fail
2:	ldi	16,0xFE
	andi	16,0xE8
	cpi	16,0xE8
	breq	2f
	break		; Fail
2:	andi	16,1
	breq	2f
	break		; Fail
2:
;
;	ASR
;
test10:	ldi	20,0xC2
	asr	20
	cpi	20,0xE1
	breq	2f
	break		; Fail	
2:	asr	20
	brmi	3f
	break		; Fail	
3:	brcs	4f
	break		; Fail	
4:	ldi	21,0x7E
	asr	21
	cpi	21,0x3F	
	breq	4f
	break		; Fail	
4:	brcc	4f	
	break		; Fail	
4:	
;
;	BCLR tests
;
test11:	sec
	bclr	0
	brcc	2f
	break		; Fail	
2:	sez
	bclr	1
	brne	2f
	break		; Fail	
2:	sen
	bclr	2
	brpl	2f
	break		; Fail	
2:	sev
	bclr	3
	brvc	2f
2:	ses
	bclr	4
	brge	2f
	break		; Fail	
2:	seh
	bclr	5
	brhc	2f
	break		; Fail	
2:	set
	bclr	6
	brtc	2f
	break		; Fail	
2:	sei
	bclr	7
	brid	2f
	break		; Fail	
2:
;
;	BLD
;
test12:	eor	16,16
	set
	bld	16,2
	cpi	16,0x04
	breq	2f
	break		; Fail	
2:	bld	16,1
	cpi	16,0x06
	breq	2f
	break		; Fail	
2:	bld	16,0
	cpi	16,0x07
	breq	2f
	break		; Fail	
2:	clt
	bld	16,1
	cpi	16,0x05
	breq	2f
	break		; Fail	
2:	
;
;	BRBS/BRBC
;
test13:	set
	brbs	6,2f
	break		; Fail	
2:	clt
	brbc	6,2f
	break		; Fail	
2:
;
;	BSET
;
test14:	bset	0
	brcs	2f
	break		; Fail	
2:	bset	6
	brts	2f
	break		; Fail	
2:
;	
;	BST
;	
test15:	ldi	25,0xB9
	bst	25,7
	brts	2f
	break		; Fail	
2:	bst	25,6
	brtc	2f
	break		; Fail	
2:	bst	25,1
	brtc	2f
	break		; Fail	
2:	bst	25,0
	brts	2f
	break		; Fail	
2:
;
;	CBI/SBI
;
test16:	cbi	DDRB,0
	cbi	DDRB,1
	sbi	DDRB,2
	sbi	DDRB,3
	sbi	DDRB,4
	sbi	DDRB,5
	lds	16,DDRB+IO_Base
	cpi	16,0x3C
	breq	2f
	break
2:
;
;	CBR/SBR
;
test17:	eor	29,29
	sbr	29,1
	cpi	29,1
	breq	2f
	break		; Fail
2:	cbr	29,1
	cpi	29,0
	breq	2f
	break		; Fail
2:	sbr	29,0x80
	cpi	29,0x80
	breq	2f
	break		; Fail
2:	cbr	29,0x80
	cpi	29,0
	breq	2f
2:
;
;	COM
;
test18:	eor	31,31
	cpi	31,0
	breq	2f
	break		; Fail
2:	com	31
	cpi	31,0xFF
	breq	2f
	break		; Fail
2:	ldi	30,0x95
	com	30
	cpi	30,0x6A
	breq	2f
	break		; Fail
2:	
;
;	ICALL
;
test19:	ldi	30,pm_lo8(called)
	ldi	31,pm_hi8(called)
	eor	29,29
	icall	
	cpi	29,0x29
	breq	2f
	break		; Fail
called:	ldi	29,0x29
	ret
	break		; Fail
2:
;
;	IJMP
;
test20:	ldi	30,pm_lo8(jump)
	ldi	31,pm_hi8(jump)
	ijmp
	break		; Fail
jump:	
;
;	IN
;
test21:	in	16,DDRB
	cpi	16,0x3C
	breq	2f
	break		; Fail
2:	
;
;	LD X
;
test22:	eor	0,0	; r0 = 0
	eor	1,1
	inc	1	; r1 = 1
	ldi	26,0
	eor	27,27	; x=0
	ld	16,X
	cpi	16,0
	breq	2f
	break		; Fail
2:	inc	26
	ld	16,x
	cpi	16,1
	breq	2f
	break		; Fail
2:	dec	26
	ld	16,X+
	cpi	16,0
	breq	2f
	break		; Fail
2:	ld	16,X+
	cpi	16,1
	breq	2f
	break		; Fail
2:	ld	16,-X
	cpi	16,1
	breq	2f
	break		; Fail
2:	ld	16,-X
	cpi	16,0
	breq	2f
	break		; Fail
2:
;
;	LD Y
;
test23:	eor	0,0
	eor	1,1
	inc	1
	ldi	28,0
	eor	29,29	; x=0
	ld	16,X
	cpi	16,0
	breq	2f
	break		; Fail
2:	inc	28
	ld	16,Y
	cpi	16,1
	breq	2f
	break		; Fail
2:	dec	28
	ld	16,Y+
	cpi	16,0
	breq	2f
	break		; Fail
2:	ld	16,Y+
	cpi	16,1
	breq	2f
	break		; Fail
2:	ld	16,-Y
	cpi	16,1
	breq	2f
	break		; Fail
2:	ld	16,-Y
	cpi	16,0
	breq	2f
	break		; Fail
2:
;
;	LD Z
;
test24:	eor	0,0
	eor	1,1
	inc	1
	ldi	30,0
	eor	31,31	; x=0
	ld	16,Z
	cpi	16,0
	breq	2f
	break		; Fail
2:	inc	30
	ld	16,Z
	cpi	16,1
	breq	2f
	break		; Fail
2:	dec	30
	ld	16,Z+
	cpi	16,0
	breq	2f
	break		; Fail
2:	ld	16,Z+
	cpi	16,1
	breq	2f
	break		; Fail
2:	ld	16,-Z
	cpi	16,1
	breq	2f
	break		; Fail
2:	ld	16,-Z
	cpi	16,0
	breq	2f
	break		; Fail
2:
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
