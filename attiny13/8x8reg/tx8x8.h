/* Transmit to 8x8 Debugging Matrix (8x8reg)
 * Warren W. Gay VE3WWG
 */

#ifndef TX8X8_H
#define TX8X8_H

#include <stdint.h>

extern void init8x8();				/* Initialize */
extern void tx8x8(uint8_t row0_7,uint8_t byte);	/* Send byte to row 0 to 7 */

#endif

/*
 * End tx8x8.h
 */
