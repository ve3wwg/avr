;---------------------------------------------------------------------
; Test program for bassert.h
;---------------------------------------------------------------------

#define __SFR_OFFSET 0 
	.nolist
#include <avr/io.h>
	.list
#include "bassert.h"

	.text
	.global	main

main:	bassert_init DDRB,PORTB,PB5
	bassert	4

;---------------------------------------------------------------------
; End testmain.S
;---------------------------------------------------------------------
