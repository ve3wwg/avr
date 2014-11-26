//////////////////////////////////////////////////////////////////////
// testmain.cpp -- Test sending to the 8x8reg Matrix Display
// Date: Mon Sep 29 21:08:51 2014  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <avr/io.h> 
#include <util/delay.h>

#include "tx8x8.h"

void
delay_sec(long sec) {

	for ( ; sec > 0; --sec )
		_delay_ms(1000);
}

int
main(void) {
	uint8_t byte = 0x01;
	uint8_t up = 1, intensity = 1;

	init8x8();
	delay_sec(2);

	for (;;) {
		for ( uint8_t digit = 0; digit < 8; ++digit )
			tx8x8(digit,byte++);
		++byte;

		if ( up ) {
			if ( ++intensity >= 16 )
				up = 0;
			else	tx8x8(8,intensity);	/* Increase intensity */
		} else	{
			if ( --intensity == 0 )
				up = 1;
			else	tx8x8(8,intensity);	/* Decrease intensity */
		}
	}

	return 0;
}

// End testmain.cpp
