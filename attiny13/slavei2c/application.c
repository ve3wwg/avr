//////////////////////////////////////////////////////////////////////
// application.c -- Slave I2C Application Example
// Date: Fri Feb 27 18:43:12 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <inttypes.h>
#include <avr/io.h>

#include "slavei2c.h"

#define LED	PB4

uint8_t
svc_init() {
	DDRB |= _BV(LED)|_BV(PB2)|_BV(PB3);		// Outputs
	PORTB &= ~(_BV(LED)|_BV(PB2)|_BV(PB3));		// Outputs low
	return 0x68;					// Configure I2C slave address
}

uint8_t
svc_start(uint8_t addr_rw) {
	PORTB |= _BV(LED);		// LED on
	return SVC_ACK;			// Accept slave request
}

uint8_t
svc_write(uint8_t wrdata) {
	PINB |= _BV(LED);
	PORTB |= _BV(PB2);		// Toggle PB2 on master write
	return SVC_ACK;			// ACK
}

uint16_t
svc_read(void) {
	PINB |= _BV(LED);
	PORTB |= _BV(PB3);		// Toggle PB3 on master read
	return 0xF5 << 8 | SVC_ACK;
}

void
svc_end() {
	PORTB &= ~_BV(PB2);
	PORTB &= ~_BV(PB3);
	PORTB &= ~_BV(LED);		// LED off
}

// End application.cpp
