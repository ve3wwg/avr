/*********************************************************************
 * Blink Assertion Macro Header
 * Warren W. Gay VE3WWG		Fri Oct 17 23:28:47 2014
 * LICENSE: GPL
 *********************************************************************/

#ifndef BLINKASSERT_H_
#define BLINKASSERT_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


/* Assumes GPIO is already configured for output */
void bassert_config0(volatile uint8_t *portx,unsigned bit,unsigned arg_active_high);

/* Configure GPIO for output and register GPIO bit to use */
void bassert_config(volatile uint8_t *ddrx,volatile uint8_t *portx,unsigned bit,unsigned active_high);

/* Blink n times and return */
void bassert_blink(unsigned n);

void blink_exit(unsigned rc);
void blink_abort();


#ifdef __cplusplus
}
#endif

#endif /* BLINKASSERT_H_ */


/*
 * Assertion Macro
 */
#undef blink_assert	/* Allow this to be redefined */

#ifndef NDEBUG
#define blink_assert(assertion,blinks) { if ( !(assertion) ) for(;;) bassert_blink(blinks); }
#else
#define blink_assert(assertion,blinks)
#endif


/*********************************************************************
 * End blinkassert.h
 *********************************************************************/
