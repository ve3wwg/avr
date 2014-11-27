/* Warren W. Gay VE3WWG  Sat Nov 15 21:17:43 2014
 *
 * Trace module for simulating
 */

#include <avr/io.h>
#include "avr/avr_mcu_section.h"

AVR_MCU(8000000,"attiny13a");
AVR_MCU_VOLTAGES(5,5,5);			/* vcc, avcc, and aref */
#if 0
AVR_MCU_VCD_FILE("firefly.vcd",1000000);	/* usec */

const struct avr_mmcu_vcd_trace_t _mytrace[] _MMCU_ = {
	{ AVR_MCU_VCD_SYMBOL("PORTB"), .what = (void *)&PORTB, },
	{ AVR_MCU_VCD_SYMBOL("PB0"), .mask = _BV(PB0), .what = (void *)&PORTB },
	{ AVR_MCU_VCD_SYMBOL("PB1"), .mask = _BV(PB1), .what = (void *)&PORTB },
	{ AVR_MCU_VCD_SYMBOL("PB2"), .mask = _BV(PB2), .what = (void *)&PORTB },
	{ AVR_MCU_VCD_SYMBOL("PB3"), .mask = _BV(PB3), .what = (void *)&PORTB },
	{ AVR_MCU_VCD_SYMBOL("PB4"), .mask = _BV(PB4), .what = (void *)&PORTB },
	{ AVR_MCU_VCD_SYMBOL("PB5"), .mask = _BV(PB5), .what = (void *)&PORTB },
};
#endif

/* End */

