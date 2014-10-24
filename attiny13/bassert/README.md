bassert
-------

The bassert.h file may be included in your problem child ATtiny* MCU
assembly code, to display a blink count at various points of failure.

By judicious use of blink codes, you will gain a relative indicator of
the location of the fault.  Execution never exits from the bassert macro.

More notes exist at the tail end of the bassert.h file. 

A test program testmain.S exists as an example.


FLASH COST:

	60 bytes for GPIO Setup and support routines
	 4 bytes for each use of bassert macro.

STEPS FOR USAGE:

  1)	bassert_init ddrx=DDRB, portx=PORTB, bit=PB5

	This macro must be invoked and executed to configure the GPIO
	port for output (controlling the flashing LED). This code initializes
	the GPIO to a low output level (LED off).

  2)	At a given failure point, invoke the bassert macro:

	point1: ...
		bassert	3	; Flash three times forever, for this failure

	point2: ...
		bassert 4	; Flash four times forever, for this failure


EXAMPLE:

	; #define __SFR_OFFSET 0 ; Optional
	#include <avr/io.h>
	#include <bassert.h>

	main:	bassert_init	DDRB,PORTB,PB5
		...
		brne	fault1
		...
	fault1:	bassert	3	; Blink three times for this fault
