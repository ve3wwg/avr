//////////////////////////////////////////////////////////////////////
// test1.cpp -- Test Atmega328p Blink Program
// Date: Fri Jan 23 20:36:29 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////
// 
// Use this to make sure that we are operating at 12 MHz. The LED
// is set to flash once/second, changing state every half second.
// 
//////////////////////////////////////////////////////////////////////

#include <avr/io.h>
#include <util/delay.h>

static void
set_cpu_clock() {
	CLKPR = _BV(CLKPCE);
	CLKPR = 0x00;			// No clock divisor
}

static void
led_on(unsigned on) {

	if ( on )
		PORTB |= _BV(PORTB5);	// Turn on LED 
	else	PORTB &= ~_BV(PORTB5);	// Else turn off 
}

int
main() 	{
	
	DDRB |= _BV(DDB5);

	set_cpu_clock();

	for (;;) {
		led_on(1);
		_delay_ms(500);
		led_on(0);
		_delay_ms(500);
	}

	return 0;
}

// End test1.cpp
