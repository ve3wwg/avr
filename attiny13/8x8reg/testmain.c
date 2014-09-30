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

	init8x8();
	delay_sec(2);

	for (;;) {
		for ( uint8_t digit = 0; digit < 8; ++digit )
			tx8x8(digit,byte++);

		++byte;
	}

	return 0;
}

// End testmain.cpp
