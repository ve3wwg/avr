/*********************************************************************
 * ABEKAS Video Systems Keyboard Scanner
 * Warren W. Gay VE3WWG		Tue Jul  5 20:52:36 2016
 * LICENSE: GPL
 *********************************************************************/

#define F_CPU 1000000UL // 1 MHz clock speed

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#define KEY_NONE	(9*8-1)

static uint8_t keys[9*8];		// Keybounce for each key col x row form
static uint8_t key_rx = KEY_NONE;	// Last sensed key-press
static uint8_t key_queued = 0;		// 1 if queued for SPI send
static uint16_t leds[8];		// LED settings in row x col form

/*********************************************************************
 * SPI Interrupt Service Routine
 *********************************************************************/

ISR(SPI_STC_vect) {
	uint8_t cmd = SPDR;
	uint8_t wordx, bitx;

	cmd = SPDR;			// Read sent byte (LED command)

	if ( key_queued ) {
		SPDR = key_rx;		// Queue byte to reply with
		key_queued = 0;		// Mark as sent
	} else	{
		SPDR = KEY_NONE;	// No keystroke being sent
	}

	if ( cmd != 0xFF ) {			// If not LED NOP..
		wordx = cmd & 7;		// Lower 3 bits index leds[]
		bitx = 1 << ((cmd >> 3) & 0x0F);// Bit mask for LED in leds[]
		if ( cmd & 0b10000000 )		// Enabling LED?
			leds[wordx] |= bitx;	// Yes, set LED bit on
		else	leds[wordx] &= ~bitx;	// No, reset LED bit off
	}
}

/*********************************************************************
 * Main Program
 *********************************************************************/

int
main() {
	unsigned k=0, k2=0, rx, km;
	int x;
	int m = 0;
	
	cli();

	ADCSRA 	&= ~_BV(ADEN);		// Disable ADC
	ACSR	&= _BV(ACD);		// Comparator off

	MCUCR &= ~PUD;			// Make sure pullups not disabled

	ASSR &= ~_BV(AS2);		// No TOSC2 to pin 2
	TWCR &= ~_BV(TWEN);		// Disable I2C
	MCUSR |= _BV(JTD);		// Disable JTAG
	MCUSR |= _BV(JTD);		// Disable JTAG (needs to be done twice)
	UCSRB = 0;			// Disable UART on port D
	GICR &= ~(_BV(INT1)|_BV(INT0));
	TCCR1A = 0;
	TCCR1B = 0;

	// Inputs:
	DDRD &= ~(_BV(DDD0)|_BV(DDD1)|_BV(DDD2)|_BV(DDD3)|_BV(DDD4)|_BV(DDD5)|_BV(DDD6)|_BV(DDD7));
	DDRA &= ~ _BV(DDA1);		// PORTA1 is input
	DDRB &= ~ _BV(DDB4);		// SPI /SS is input

	PORTD = _BV(PORTD0)|_BV(PORTD1)|_BV(PORTD2)|_BV(PORTD3)|_BV(PORTD4)|_BV(PORTD5)|_BV(PORTD6)|_BV(PORTD7);	// Pullups on
	PORTA = _BV(PORTA1);												// PA1 also

	// Output pins
	DDRC = _BV(DDC0)|_BV(DDC1)|_BV(DDC2)|_BV(DDC3)|_BV(DDC4)|_BV(DDC5)|_BV(DDC6)|_BV(DDC7);
	DDRB |= _BV(DDB0)|_BV(DDB1)|_BV(DDB2)|_BV(DDB3);
	DDRA |= _BV(DDA0);

	PORTA |= _BV(PORTA0);		// Disable blink LED

	// SPI
	SPCR &= ~(_BV(DORD)|_BV(MSTR)|_BV(CPOL)|_BV(CPHA));	// DORD=0 MSB first, MSTR=0 for slave mode, SPI mode 0,0
	SPCR |= _BV(SPIE)|_BV(SPE);				// Interrupt enable + SPI enable
	x = SPSR;
	x = SPDR;			// Clear WCOL & SPIF if set

	sei();

	for ( x=0; x<sizeof keys; ++x )
		keys[x] = 0;
	for ( x=0; x<8; ++x )
		leds[x] = 0;

	for ( x=0;;) {
		m >>= 1;

		PORTB |= _BV(PB3);	// /OE = off
		if ( !m ) {
			m = 0b10000000;		// Restart mask
			x = (x+1) & 7;		// A2..A0 increment (scan);
			PORTB = _BV(PORTB3) | x;
		}

		k = (~(unsigned)PIND) & 0x00FF;		// Read keyboard
		k2 = ((~(unsigned)PINA) >> 1) & 1;	// Read bit PORTA2
		k |= k2 << 8;

		PORTB &= ~_BV(PORTB3);

		PORTC = ~( m & leds[x] );

		rx = (unsigned)x * 9u;
		for ( km = 1; km != 0b01000000000; km <<= 1 ) {
			keys[rx] = ( keys[rx] << 1 ) | (!!(k & km));

			if ( rx != key_rx && (keys[rx] & 0x07) == 0x07 ) {
				PORTA &= ~_BV(PORTA0);

				cli();
				key_rx = rx;			// Save key down index
				key_queued = 1;			// Mark ready for SPI transmission
				sei();

				leds[x] ^= km;			// Toggle LED
			}

			if ( rx == key_rx && (keys[rx] & 0x07) == 0x00 ) {
				PORTA |= _BV(PORTA0);		// Disable blink LED
				key_rx = KEY_NONE;
			}
			++rx;
		}
	}
}

/*********************************************************************
 * End kbscan.c
 *********************************************************************/
