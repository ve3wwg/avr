/*********************************************************************
 * Test Main Program for blinkassert.h
 * Warren W. Gay VE3WWG		Fri Oct 17 23:28:47 2014
 * LICENSE: GPL
 *********************************************************************/

#include <avr/io.h>
#include "blinkassert.h"

int
main() {

	bassert_config(&DDRB,&PORTB,PB5,1);	/* Active high */
	
	blink_assert(1==1,6);			/* This should pass ok */
	blink_assert(1==0,5);			/* This should trigger */

	return 0;
}

/*********************************************************************
 * End testmain.c
 *********************************************************************/
