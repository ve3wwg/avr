///////////////////////////////////////////////////////////////////////
// dlg1414.cpp -- DLG-1414 LED Driver
// Date: Fri Oct 14 21:23:36 2016  (C) Warren W. Gay VE3WWG 
// License: GPLv3
///////////////////////////////////////////////////////////////////////
//
//  This source code drives a reverse engineered PCB from some
//  ancient piece of equipment, from a far away galaxy.. The number
//  on the PCB was PC1031-0B (bottom) and PC1031-OT (topside).
//
//  The PCB housed 8 x DLG-1414 modules, each with 4 characters of
//  display. You could also use DLR-1414 or DLO-1414 modules instead,
//  if you like red or bright red. The DLG-1414 are green.
//
//  The pcb uses 2 x CD4094 shift registers, 1 x CD4001 and one
//  CD4021 to read the optional pushbuttons. The shift register
//  allows use of a 24-bit command word to control the display
//  modules.
//
//  24-BIT COMMAND STRUCTURE:
//
//      bit     Function
//      ===     ================
//      0       /WR 0
//      1       /WR 1
//      2       /WR 2
//      3       /WR 3
//      4..7    LED 0..3
//      8       D3
//      9       D2
//      10      D1
//      11      D0
//      12..15  LED 4..7
//      16      D5
//      17      D4
//      18      A1
//      19      A0
//      20      /WR 4
//      21      /WR 5
//      22      /WR 6
//      23      /WR 7
//    
//  NOTES:
//      1.  D6 is delivered through the pcb hack:
//          The last bit is clocked in with a clock
//          pulse (CP) like all bits except that:
//  
//          If CP is left high when STR is asserted,
//          then D6=0 until the STR is returned low.
//
//          If CP is LOW when STR is asserted, then
//          pin 2 of CD4001 is 2.5 volts, by means
//          of voltage divider resistors. This level is
//          lower than the VIH=3 to 3.5 volts of CD4001.
//          Since it is a NOR gate, the output to D6 is
//          inverted as D6=1.
//
//	2.  This code assumes that only PORTD will be
//          used to interface with the pcb. Macros CP,
//          STR, D and PBD can be modified. But if they
//          refer to a port other than D, you will need
//          to do some software porting.
//
//////////////////////////////////////////////////////////////////////
    
#include <inttypes.h>
#include <avr/io.h>
#include <util/twi.h>
#include <util/delay.h>

//////////////////////////////////////////////////////////////////////
// PORTD Macros:
//
// d0	PD0	^CP  (rising)
// d1	PD1	vSTR (falling)
// d2	PD2	D
// d3	PD3	PBD (input data)
//////////////////////////////////////////////////////////////////////

#define CP	PD0     // Clock Pulse (rising edge)
#define STR	PD1     // Strobe (Active high, latched on falling edge)
#define D	PD2     // Data to displays
#define PBD	PD3     // Push button data (input)

//////////////////////////////////////////////////////////////////////
// The DLG_1414 Driver Class
//////////////////////////////////////////////////////////////////////

class DLG_1414 {
	union	{
		uint32_t	cmd;	// 24-bit command word
		struct	{
			unsigned	wr03 : 4;	// /WR0..3 (LSB)
			unsigned	led03 : 4;	// /LED0..3
			unsigned	d3 : 1;		// D3
			unsigned	d2 : 1;		// D2
			unsigned	d1 : 1;
			unsigned	d0 : 1;
			unsigned	led47 : 4;	// /LED4..7
			unsigned	d5 : 1;		// D5
			unsigned	d4 : 1;		// D4
			unsigned	a1 : 1;		// A1
			unsigned	a0 : 1;		// A0
			unsigned	wr47 : 4;	// /WR4..7
			unsigned	d6 : 1;		// D6
			unsigned	fill : 7;	// MSB
		} sr;
	} u;
	unsigned	leds;		// Saved LED settings
	union 	{
		uint8_t	indata;
		struct { 		// Input order
			unsigned pb4 : 1;
			unsigned pb3 : 1;
			unsigned pb2 : 1;
			unsigned pb1 : 1;
			unsigned pb7 : 1;
			unsigned pb6 : 1;
			unsigned pb5 : 1;
			unsigned pb0 : 1;
		} sr;
	} pb;
	unsigned	pbdata;		// Input push button data

protected:
	void write_cmd(uint32_t cmd);           // Internal

public:	DLG_1414();
	void writec(char c,unsigned digit);	// Write character
	unsigned read();			// Read pushbuttons
	bool set_led(bool b,unsigned led);	// Set one LED
	unsigned get_buttons() { return pbdata; }
};
	
//////////////////////////////////////////////////////////////////////
// Internal signal output function
//////////////////////////////////////////////////////////////////////

static void
put_sigs(uint8_t s) {
	static const uint8_t mask = _BV(CP)|_BV(STR)|_BV(D);
	uint8_t temp = PORTD & ~mask;

	PORTD = temp | (s & mask);
}

//////////////////////////////////////////////////////////////////////
// DLG_1414 Constructor
//////////////////////////////////////////////////////////////////////

DLG_1414::DLG_1414() {
	DDRD |= _BV(CP)|_BV(STR)|_BV(D); // outputs
	DDRD &= ~_BV(PBD);		 // input
	put_sigs(0);			 // clear line state
	leds = 0;
	pbdata = 0;
};

//////////////////////////////////////////////////////////////////////
// Internal: Write a 24-bit command to display driver pcb
//////////////////////////////////////////////////////////////////////

void
DLG_1414::write_cmd(uint32_t cmd) {
	uint32_t sr = cmd;
	uint8_t d;

	for ( int x=0; x<24; ++x ) {
		d = (sr & (uint32_t(1) << 23)) ? 1 : 0;
		sr <<= 1;
		put_sigs(d ? _BV(D) : 0);	// D first, CP=0
		put_sigs((d ? _BV(D) : 0)|_BV(CP)); // Raise CP=1
	}

	if ( (cmd & (uint32_t(1) << 24)) != 0 ) { // D6?
		put_sigs(_BV(STR));		// CP=0 & STR=1 => D6=1
	} else	{
		put_sigs(_BV(CP)|_BV(STR));	// CP=1 & STR=1 => D6 = 0
	}

	put_sigs(0);				// CP=0, STR=0
	read();
//	leds = pbdata;		// Leave this in for push button demo
}

//////////////////////////////////////////////////////////////////////
// Force read of push button data (must occur after STR set low)
//////////////////////////////////////////////////////////////////////

unsigned
DLG_1414::read() {
	int x;

	pbdata = 0;
	for ( x=0; x<8; ++x ) {
		pb.indata = (pb.indata << 1) | (!(PIND & _BV(PBD)));
		put_sigs(_BV(CP));
		put_sigs(0);
	}

	// Unscramble this willy nilly mess
	pbdata =  pb.sr.pb7 << 7
		| pb.sr.pb6 << 6
		| pb.sr.pb5 << 5
		| pb.sr.pb4 << 4
		| pb.sr.pb3 << 3
		| pb.sr.pb2 << 2
		| pb.sr.pb1 << 1
		| pb.sr.pb0;
	return pbdata;
}

//////////////////////////////////////////////////////////////////////
// Write one character at digit position
//////////////////////////////////////////////////////////////////////

void
DLG_1414::writec(char c,unsigned digit) {
	uint8_t uc = uint8_t(c);	// Unsigned char
	unsigned m = digit >> 2;	// Module select 0..7
	uint8_t d = (uint8_t(digit) & 3u) ^ 3; // Digit 0..3
	uint32_t msel;			// Module select /WR=1

	if ( m <= 3 )
		msel = (1 << m);	// First group
	else 	msel = (uint32_t(1) << uint32_t(m-4)) << 20;

	u.cmd = 0;
	u.sr.wr03 = u.sr.wr47 = 0x0F;	// all /WR=1
	u.sr.a0 = !!(d & 1);		// A0
	u.sr.a1 = !!(d & 2);		// A1
	u.sr.d0 = !!(uc & 0x01);	// D0 ..
	u.sr.d1 = !!(uc & 0x02);
	u.sr.d2 = !!(uc & 0x04);
	u.sr.d3 = !!(uc & 0x08);
	u.sr.d4 = !!(uc & 0x10);
	u.sr.d5 = !!(uc & 0x20);
	u.sr.d6 = !!(uc & 0x40);	// D6

	// Maintain existing LED status
	u.sr.led03 = (leds & 0x0F) ^ 0x0F;
	u.sr.led47 = (leds >> 4) ^ 0x0F;

	write_cmd(u.cmd);		// /WR=1, stabilize A1,A0
	write_cmd(u.cmd^msel);		// /WR=0
	write_cmd(u.cmd);		// /WR=1
}

//////////////////////////////////////////////////////////////////////
// Set/Reset a particular LED (on push buttons)
//////////////////////////////////////////////////////////////////////

bool
DLG_1414::set_led(bool b,unsigned led) {
	unsigned before = leds;
	unsigned mask = 1 << led;

	if ( b )
		leds |= mask;
	else	leds &= ~mask;

	if ( leds != before ) {
		u.cmd = 0;
		u.sr.wr03 = u.sr.wr47 = 0x0F;	// all /WR=1
		u.sr.led03 = (leds & 0x0F) ^ 0x0F;
		u.sr.led47 = (leds >> 4) ^ 0x0F;
		write_cmd(u.cmd);
	}
	return !!(leds & mask);
}

//////////////////////////////////////////////////////////////////////
// Test program
//////////////////////////////////////////////////////////////////////

int
main() {
	DLG_1414 dlg1414;	// Instantiated class
	char c;			// Temp. Character to display
	unsigned dx;		// Temp. Digit index

	for (;;) {
		c = '0';
		// Display 8 modules (8x4 characters)
		for ( dx=0; dx<32; ++dx ) {
			dlg1414.writec(c,dx);
			++c;
		}
		_delay_ms(600);
	}

	return 0;
}

// End dlg1414.cpp
