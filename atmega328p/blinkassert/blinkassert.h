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


void bassert_config(volatile uint8_t *ddrx,volatile uint8_t *portx,unsigned bit,unsigned active_high);
void bassert_blink(unsigned n);


#ifndef NDEBUG
#define blink_assert(assertion,blinks) { if ( !(assertion) ) for(;;) bassert_blink(blinks); }
#else
#define blink_assert(assertion,blinks)
#endif


#ifdef __cplusplus
}
#endif

#endif /* BLINKASSERT_H_ */

/*********************************************************************
 * End blinkassert.h
 *********************************************************************/
