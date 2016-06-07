/*********************************************************************
 * Workstation Module
 * Warren W. Gay VE3WWG		Sun May 29 17:30:49 2016
 * LICENSE: GPL
 *********************************************************************/

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#define COUNT	500			// Timer count

static const int adc_lim = 1016;	// Pulse output if < than this (1 & 2)

static uint8_t sr[4] = { 0, 0, 0, 0 };	// Debounce shift registers
static uint8_t st[4] = { 0, 0, 0, 0 };	// State of each output 
static uint8_t pb[4] = { 2, 2, 2, 2 };	// State of the push button
static uint16_t av[2] = { 0, 0 };	// Analog values for ADC0, 1
static uint16_t tm[2] = { 0, 0 };	// Timer count down values 0/1
static uint8_t adcx = 0;		// Which ADC is operating

/*********************************************************************
 * Initialize the ADC Controller
 *********************************************************************/

static void
init_adc(void) {
        cli();
        ADCSRA |= _BV(ADEN);            // Enable ADC
        ADMUX &= ~_BV(REFS1);
        ADMUX |= _BV(REFS0);            // Use AVcc Ref
        ADMUX &= ~_BV(ADLAR);         	// ADLAR=0 right justified value
        ADMUX &= 0xF0;                  // Select ADC0
        ADCSRA &= ~_BV(ADATE);          // ADATE=0 auto trigger off
        ADCSRA &= ~_BV(ADIE);           // ADIE=0 interrupts off
        ADCSRA &= 0b11111000;           // Prescale..
        ADCSRA |= 0b00000011;           // Prescale = 8
        DIDR0 = 0b00000011;             // Disable digital input on ADC0/1
        ADCSRA |= _BV(ADIF);            // Clear interrupt
        sei();
}

/*********************************************************************
 * Initialize Interrupt Driven Timer
 *********************************************************************/

static void
init_timer(void) {

	cli();
        TIMSK1 = 0b00000000;            // Disable timer interrupts
	TCCR1A = 0b00000000;		// CTC mode..
        TCCR1B = 0b00001001;            // CTC mode, divisor=1
        TCCR1C = 0b00000000;
	OCR1AH = COUNT >> 8;
	OCR1AL = COUNT & 0xFF;
        TIFR1  = 0b00000111;            // Reset interrupt flags
        TIMSK1 = 0b00000010;            // Enable OCRA interrupt

        sei();
}

/*********************************************************************
 * Start the ADC controller (selected by adcx)
 *********************************************************************/

static void
start_adc(void) {
        ADMUX &= 0b11110000;            // Select ADC0
        if ( adcx )
                ADMUX |= 1;             // Select ADC1
        ADCSRA |= _BV(ADSC);    	// Start ADC
}

/*********************************************************************
 * Get Port Routines
 *********************************************************************/

static int
getport0() {
        return !!(PINB & _BV(PINB0));
}
static int
getport1() {
        return !!(PIND & _BV(PIND7));
}
static int
getport2() {
        return !!(PIND & _BV(PIND6));

}
static int
getport3() {
        return !!(PIND & _BV(PIND5));
}

/*********************************************************************
 * Set port routines
 *********************************************************************/

static void
setport0(int v) {
        if ( v ) {
                PORTD |= _BV(PORTD4);
                PORTB |= _BV(PORTB2);
        } else  {
                PORTD &= ~_BV(PORTD4);
                PORTB &= ~_BV(PORTB2);
        }
}
static void
setport1(int v) {
        if ( v ) {
                PORTD |= _BV(PORTD3);
                PORTB |= _BV(PORTB3);
        } else  {
                PORTD &= ~_BV(PORTD3);
                PORTB &= ~_BV(PORTB3);
        }
}
static void
setport2(int v) {
        if ( v ) {
                PORTD |= _BV(PORTD2);
                PORTB |= _BV(PORTB4);
        } else  {
                PORTD &= ~_BV(PORTD2);
                PORTB &= ~_BV(PORTB4);
        }
}
static void
setport3(int v) {
        if ( v ) {
                PORTD |= _BV(PORTD1);
                PORTB |= _BV(PORTB5);
        } else  {
                PORTD &= ~_BV(PORTD1);
                PORTB &= ~_BV(PORTB5);
        }
}

/*********************************************************************
 * Get port x value
 *********************************************************************/

static int
getport(int x) {
        static int (*ports[])(void) = { getport0, getport1, getport2, getport3 };

        return ports[x]();
}

/*********************************************************************
 * Set port x value
 *********************************************************************/

static void
setport(int x,int v) {
        static void (*ports[])(int v) = { setport0, setport1, setport2, setport3 };

        ports[x](v);
}

/*********************************************************************
 * Timer Interrupt
 *********************************************************************/

ISR(TIMER1_COMPA_vect) {
	static uint8_t x = 0;

	if ( av[x] < adc_lim ) {
		if ( !tm[x] ) {
			tm[x] = av[x] << 2;
			setport(x,st[x]^=1);
		} else	{
			--tm[x];
		}
	} 
	x ^= 1;
}

/*********************************************************************
 * Debounce Keypress
 *
 * Returns:
 *	0	Key pressed (debounced)
 *	1	Key released (debounced)
 * 	2	Key bouncing
 *********************************************************************/

static int
debounce(int x) {
	static const uint8_t mask = 0x07;

	sr[x] = (sr[x] << 1) | getport(x);	// Shift register debouncing
	if ( (sr[x] & mask) == 0 )
		return 0;			// Button pressed
	else if ( (sr[x] & mask) == mask )
		return 1;			// Button released
	else	return 2;			// Bouncing
}

/*********************************************************************
 * Read ADC Input
 *********************************************************************/

static void
read_adc(void) {
	cli();
	av[adcx] = ADCL;
	av[adcx] |= ((ADCH & 3) << 8);
	sei();
	ADCSRA |= _BV(ADIF);		// Clear interrupt flag
	adcx ^= 1;			// Switch to the other ADC
	start_adc();			// Start it
}

/*********************************************************************
 * Poll four keys and manage key state changes
 *********************************************************************/

static void
keys(void) {
	int x, s;

	if ( ADCSRA & _BV(ADIF) )		// Have data?
		read_adc();			// Update ADC readings

	for ( x=0; x<4; ++x ) {
		s = debounce(x);			// State of key press
		if ( s != 2 ) {				// Not bouncing?
			if ( pb[x] != s ) {		// Key state different than before?
				pb[x] = s;		// Yes, save new state
				if ( s == 0 )		// Keypress?
					setport(x,st[x] ^= 1); // Yes, toggle output state
			}
		}
	}
}

/*********************************************************************
 * Main Program
 *********************************************************************/

int
main() {
	static const int dcount = 3000;
	int x;

	// Output pins
	DDRB = _BV(DDB1)|_BV(DDB2)|_BV(DDB3)|_BV(DDB4)|_BV(DDB5);
	DDRD = _BV(DDD4)|_BV(DDD3)|_BV(DDD2)|_BV(DDD1);

	// Pullups
	MCUCR &= ~PUD;		// Make sure pullups not disabled
	PORTB |= _BV(PORTB0);
	PORTD |= _BV(PORTD7)|_BV(PORTD6)|_BV(PORTD5);

	// CPU clock to 8 MHz (vs default 1 MHz)
	CLKPR = _BV(CLKPCE);	// Enable divisor change
	CLKPR = 0b00000000;	// Divisor = 1

	init_adc();
	init_timer();
	start_adc();

	for (;;) {
		PORTB |= _BV(PORTB1);
		for ( x=0; x<dcount; ++x )
			keys();

		PORTB &= ~_BV(PORTB1);
		for ( x=0; x<dcount; ++x )
			keys();
	}
}

/*********************************************************************
 * End wsmodule.c
 *********************************************************************/
