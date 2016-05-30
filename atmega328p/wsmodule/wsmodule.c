/*********************************************************************
 * Workstation Module
 * Warren W. Gay VE3WWG		Sun May 29 17:30:49 2016
 * LICENSE: GPL
 *********************************************************************/

#include <avr/io.h>
#include <util/delay.h>

static uint8_t sr[4] = { 0, 0, 0, 0 };	// Debounce shift registers
static uint8_t st[4] = { 0, 0, 0, 0 };	// State of each output 
static uint8_t pb[4] = { 9, 9, 9, 9 };	// State of the push button

static int
getport1() {
	return !!(PINB & _BV(PINB0));
}

static int
getport2() {
	return !!(PIND & _BV(PIND7));
}

static int
getport3() {
	return !!(PIND & _BV(PIND6));

}

static int
getport4() {
	return !!(PIND & _BV(PIND5));
}

static void
setport1(int v) {
	if ( v ) {
		PORTD &= ~_BV(PORTD4);
		PORTB &= ~_BV(PORTB2);
	} else	{
		PORTD |= _BV(PORTD4);
		PORTB |= _BV(PORTB2);
	}
}

static void
setport2(int v) {
	if ( v ) {
		PORTD &= ~_BV(PORTD3);
		PORTB &= ~_BV(PORTB3);
	} else	{
		PORTD |= _BV(PORTD3);
		PORTB |= _BV(PORTB3);
	}
}

static void
setport3(int v) {
	if ( v ) {
		PORTD &= ~_BV(PORTD2);
		PORTB &= ~_BV(PORTB4);
	} else	{
		PORTD |= _BV(PORTD2);
		PORTB |= _BV(PORTB4);
	}
}

static void
setport4(int v) {
	if ( v ) {
		PORTD &= ~_BV(PORTD1);
		PORTB &= ~_BV(PORTB5);
	} else	{
		PORTD |= _BV(PORTD1);
		PORTB |= _BV(PORTB5);
	}
}

static int
getport(int x) {
	static int (*ports[])(void) = { getport1, getport2, getport3, getport4 };

	return ports[x]();
}

static void
setport(int x,int v) {
	static void (*ports[])(int v) = { setport1, setport2, setport3, setport4 };

	ports[x](v);
}

/*********************************************************************
 * Debounce kepress
 *
 * Returns:
 *	0	Key pressed (debounced)
 *	1	Key released (debounced)
 * 	2	Key bouncing
 *********************************************************************/

static int
debounce(int x) {
	sr[x] = (sr[x] << 1) | getport(x);	// Shift register debouncing

	if ( (sr[x] & 0x0F) == 0x00 )
		return 0;			// Button pressed
	else if ( (sr[x] & 0x0F) == 0x0F )
		return 1;			// Button released
	else	return 2;			// Bouncing
}

/*********************************************************************
 * Toggle upon first keypress event
 *********************************************************************/

static void
toggle(int x) {
	int s = debounce(x);			// State of key press

	if ( s != 2 ) {				// Not bouncing?
		if ( pb[x] != s ) {		// Key state different than before?
			pb[x] = s;		// Yes, save new state
			if ( s == 0 )		// Keypress?
				setport(x,st[x] ^= 1); // Yes, toggle output state
		}
	}
}

/*********************************************************************
 * Poll four keys and manage key state changes
 *********************************************************************/

static void
keys(void) {
	int x;

	for ( x=0; x<4; ++x )
		toggle(x);
}

/*********************************************************************
 * Main Program
 *********************************************************************/

int
main() {
	int x;

	// Output pins
	DDRB = _BV(DDB1)|_BV(DDB2)|_BV(DDB3)|_BV(DDB4)|_BV(DDB5);
	DDRD = _BV(DDD4)|_BV(DDD3)|_BV(DDD2)|_BV(DDD1);

	// Pullups
	PORTB |= _BV(PORTB0);
	PORTD |= _BV(PORTD7)|_BV(PORTD6)|_BV(PORTD5);

	for (;;) {
		PORTB |= _BV(PORTB1);
		for ( x=0; x<500; ++x )
			keys();

		PORTB &= ~_BV(PORTB1);
		for ( x=0; x<500; ++x )
			keys();
	}
}

/*********************************************************************
 * End wsmodule.c
 *********************************************************************/
