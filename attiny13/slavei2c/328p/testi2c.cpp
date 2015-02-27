//////////////////////////////////////////////////////////////////////
// testi2c.cpp
// Date: Mon Feb 16 12:05:47 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

#include <avr/io.h>
#include <util/twi.h>
#include <util/delay.h>

#include "i2cmaster.hpp"

static uint8_t RTC_address = 0x70;

#define LED	PB5

static void
ports_init() {

	// Define outputs
	DDRB = _BV(PB5);

	// I2C in master mode
	I2C_init();
}

int
main() {

	ports_init();
	PORTB |= _BV(LED);

	if ( I2C_start(RTC_address,false) )
		goto oops;
	if ( I2C_write(0x00) )
		goto oops;
	I2C_stop();

	PORTB |= _BV(LED);

	for (;;)
		;

oops:	for (;;) {
		PORTB &= _BV(LED);
	}

#if 0
	I2C_start(RTC_address,true);
	I2C_read_ack(); // Ignore
	bmin = I2C_read_ack();
	bhour = I2C_read_nack();
	I2C_stop();
#endif
	return 0;
}

// End testi2c.cpp
