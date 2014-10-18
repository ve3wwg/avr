/*********************************************************************
 * Blink Assertion Routines
 * Warren W. Gay VE3WWG		Fri Oct 17 23:28:47 2014
 * LICENSE: GPL
 *********************************************************************/

#include <avr/io.h>
#include <util/delay.h>
#include "blinkassert.h"

static volatile uint8_t *port;
static uint8_t blkbit;
static uint8_t active_high;

/*********************************************************************
 * Configure the port used for blinking
 *********************************************************************/

void
bassert_config(volatile uint8_t *ddrx,volatile uint8_t *portx,unsigned bit,unsigned arg_active_high) {

	*ddrx = _BV(bit);			/* Configure this bit as output */
	port = portx;				/* Save ref to port to use for output */
	blkbit = bit;				/* Save the bit # */
	active_high = !!arg_active_high;	/* Set to 1 for active high, else 0 for active_low */
}

/*********************************************************************
 * Blink once, active high or low
 *********************************************************************/

static void
blink(void) {

	if ( active_high )
		*port |= _BV(blkbit);		/* Turn on LED (and bit) when active high */
	else	*port &= ~_BV(blkbit);		/* Else turn off bit (active low) */

	_delay_ms(900);

	if ( active_high )
		*port &= ~_BV(blkbit);		/* Turn off LED (and bit) when active high */
	else	*port |= _BV(blkbit);		/* Turn on bit (active low) */

	_delay_ms(800);
}

/*********************************************************************
 * This routine never returns: Blink the count n, pause and repeat
 *********************************************************************/

void
bassert_blink(unsigned count) {

	for ( ; count > 0; --count )
		blink();		/* Blink once */
	_delay_ms(2000);		/* Pause between blinks */
}


/*********************************************************************
 * End blinkassert.c
 *********************************************************************/
