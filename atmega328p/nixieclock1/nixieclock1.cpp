//////////////////////////////////////////////////////////////////////
// nixieclock1.cpp -- Nixie Tube Clock 1
// Date: Mon Feb 16 12:05:47 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

#include <avr/io.h>
#include <util/twi.h>
#include <util/delay.h>

#include "i2cmaster.hpp"

static uint8_t RTC_address = 0x68;
static uint8_t digits[4] = { 0, 0, 0, 0 };

#define hr_tens		digits[0]
#define hr_ones		digits[1]
#define min_tens	digits[2]
#define min_ones	digits[3]

static int LED = 0;

static void
dispdigit(int digit,int value) {
	unsigned pb = 0, pc = 0;
	
	digit &= 0x03;
	value &= 0x0F;

	switch ( digit ) {
	case 0 :
		pb = _BV(PB0);
		break;
	case 1 :
		pb = _BV(PB1);
		break;
	case 2 :
		pb = _BV(PB2);
		break;
	case 3 :
		pc = _BV(PC0);
		break;
	}

	if ( LED & 1 )
		pb |= _BV(PB5);

	PORTB = 0x00;		// Turn off all anodes	
	PORTC = 0x00;	

	_delay_us(250.0);	// Blanking period

	PORTD = value << 2;	// Turn on one cathode
	if ( pc )
		PORTC = pc;	// Or this one
	else if ( pb )
		PORTB = pb;	// Select anode

	_delay_ms(2.0);		// Delay 2 ms
}

static void
display() {
	for ( int dx=0; dx < 4; ++dx )
		dispdigit(dx,digits[dx]);
}

static int
read_rtc() {
	uint8_t bmin, bhour;
	uint8_t min10, min1, hr10, hr1;

	if ( I2C_start(RTC_address,false) )
		return -1;	// Error
	if ( I2C_write(0x00) )
		return -1;	// Error
	I2C_stop();

	I2C_start(RTC_address,true);
	I2C_read_ack(); // Ignore
	bmin = I2C_read_ack();
	bhour = I2C_read_nack();
	I2C_stop();

	min10 = (bmin >> 4) & 0x0F;
	min1 = bmin & 0x0F;
	hr10 = (bhour >> 4) & 0x03;
	hr1  = bhour & 0x0F;

	if ( hr10 != hr_tens || hr1 != hr_ones || min10 != min_tens || min1 != min_ones ) {
		hr_tens = hr10;
		hr_ones = hr1;
		min_tens = min10;
		min_ones = min1;
		return 1;		// Changed
	}
	
	return 0;			// No change
}

static void
ports_init() {

	// Define outputs
	DDRD = _BV(PD5)|_BV(PD4)|_BV(PD3)|_BV(PD2);
	DDRC = _BV(PC0);
	DDRB = _BV(PB0)|_BV(PB2)|_BV(PB1)|_BV(PB5);

	// I2C in master mode
	I2C_init();
}

int
main() {

	ports_init();

	for (;;) {
		for ( int tx=0; tx<400; ++tx ) {
			display();
			if ( tx % 50 == 0 ) {
				switch ( read_rtc() ) {
				case -1:
					break;
				case 0:
					break;
				case 1:
					break;
				}
			}
		}

		LED ^= 1;

		++digits[0];
		for ( int dx=0; dx<4; ++dx ) {
			if ( digits[dx] > 9 ) {
				digits[dx] = 0;
				if ( dx+1 < 4 )
					++digits[dx+1];
			}
		}
	}

	return 0;
}

// End nixieclock1.cpp
