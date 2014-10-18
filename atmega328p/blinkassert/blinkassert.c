/*********************************************************************
 * Blink Assertion Routines
 * Warren W. Gay VE3WWG		Fri Oct 17 23:28:47 2014
 * LICENSE: GPL
 *********************************************************************/

#include <avr/io.h>
#include <util/delay.h>
#include "blinkassert.h"

/*********************************************************************
 * Times are in milliseconds
 *********************************************************************/

#define BLINK_ON	900
#define BLINK_OFF	800
#define BLINK_PAUSE	2400

#define ABTXIT_LONG	2800
#define ABTXIT_SHORT	200

/*********************************************************************
 * Configuration Values:
 *********************************************************************/

static volatile uint8_t *port;			/* Configured LED port to use */
static uint8_t blkbit;				/* Configured GPIO port to use */
static uint8_t active_high;			/* Configured active level: 0 == active low, else high */

/*********************************************************************
 * Configure the port used for blinking (assumes GPIO is already
 * configured for output.
 *********************************************************************/

void
bassert_config0(volatile uint8_t *portx,unsigned bit,unsigned arg_active_high) {

	port = portx;				/* Save ref to port to use for output */
	blkbit = bit;				/* Save the bit # */
	active_high = !!arg_active_high;	/* Set to 1 for active high, else 0 for active_low */
}

/*********************************************************************
 * Configure the port used for blinking (configures GPIO for output)
 *********************************************************************/

void
bassert_config(volatile uint8_t *ddrx,volatile uint8_t *portx,unsigned bit,unsigned active_high) {

	*ddrx = _BV(bit);			/* Configure this bit as output */
	bassert_config0(portx,bit,active_high);
}

/*********************************************************************
 * Internal: Turn LED on taking into account active_high setting
 *********************************************************************/

static void
led_on(unsigned on) {
	int h = (!on) ^ active_high;

	if ( h )
		*port |= _BV(blkbit);		/* Turn on LED (and bit) when active high */
	else	*port &= ~_BV(blkbit);		/* Else turn off bit (active low) */
}

/*********************************************************************
 * Internal: Blink once, active high or low
 *********************************************************************/

static void
blink(void) {

	led_on(1);
	_delay_ms(BLINK_ON);
	led_on(0);
	_delay_ms(BLINK_OFF);
}

/*********************************************************************
 * This routine never returns: Blink the count n, pause and repeat
 *********************************************************************/

void
bassert_blink(unsigned count) {

	if ( !count ) {			/* If count == 0 */
		led_on(1);		/* then just turn on the LED */
	} else	{
		for ( ; count > 0; --count )
			blink();	/* Blink once */
	}
	_delay_ms(BLINK_PAUSE);		/* Pause between blinks */
}

/*********************************************************************
 * Perform an exit(2) call with blink indication:
 *
 * When rc == 0 :	Blink long on, with short off
 *      rc != 0 :	Else blinks rc as if bassert_blink(rc) called.
 *********************************************************************/

void
blink_exit(unsigned rc) {

	if ( rc ) {
		for (;;)
			bassert_blink(rc);
	} else	{
		for (;;) {
			led_on(1);
			_delay_ms(ABTXIT_LONG);
			led_on(0);
			_delay_ms(ABTXIT_SHORT);
		}
	}
	/* Never returns */
}

/*********************************************************************
 * Perform an abort(2) call with blink indication:
 *
 * Blinks:
 *	On	Briefly
 *	Off	Long
 *********************************************************************/

void
blink_abort() {

	for (;;) {
		led_on(1);
		_delay_ms(ABTXIT_SHORT);
		led_on(0);
		_delay_ms(ABTXIT_LONG);
	}
	/* Never returns */
}

/*********************************************************************
 * End blinkassert.c
 *********************************************************************/
