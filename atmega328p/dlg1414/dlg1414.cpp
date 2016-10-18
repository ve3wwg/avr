///////////////////////////////////////////////////////////////////////
// dlg1414.cpp -- DLG-1414 LED Driver
// Date: Fri Oct 14 21:23:36 2016  (C) Warren W. Gay VE3WWG 
// License: GPLv3
///////////////////////////////////////////////////////////////////////
//
//  PCB requires one modification (see Notes).
//
//  This source code drives a reverse engineered PCB from some
//  ancient piece of equipment, from a far away galaxy.. The number
//  on the PCB was PC1031-0B (bottom) and PC1031-OT (topside).
//
//  The PCB housed 8 x DLG-1414 modules, each with 4 characters of
//  display. You could also use DLR-1414 or DLO-1414 modules instead,
//  if you like red or bright red. The DLG-1414 modules are green.
//
//  The pcb uses 3 x CD4094 shift registers, 1 x CD4001 and one
//  CD4021 to read the optional pushbuttons. The shift register
//  allows use of a 24-bit command word to control the display
//  modules.
//
//  PCB CONNECTIONS
//
//  Looking at the back of the PCB, with the connections appearing
//  at the upper right hand corner:
//  
//      --------------------------+
//          +5V Supply..........O |
//          Push Button Data....O |
//          Command Data........O |
//          Strobe (STR)........O |
//          Clock Pulse (CP)....O |
//          Ground..............O |
//       pcb (bottom view)        |
//                                |
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
//     (24)     D6      From IC3.Q7S output
//    
//  NOTES:
//      1.  D6 is delivered through Q7S of IC3 (CD4094).
//          The pcb must be modified as follows:
//  
//          i)  Remove IC4 (CD4001), it is not required
//          ii) Solder a wire from IC4's pin 3 to IC3's
//              pin 10 (Q7S).
//
//          This modification permits display of the
//          entire DLG-1414 character set.
//
//	2.  This code assumes that only PORTD will be
//          used to interface with the pcb. Macros CP,
//          STR, D and PBD can be modified. But if they
//          refer to a port other than D, you will need
//          to do some software porting.
//
//      3.  If your code writes _continually_ to the DLG-1414
//          modules, you will likely see twinkling in the
//          character output. This is due to the module's
//          internal scan of the characters being continually
//          interrupted by your writes. It is best to write
//          messages to the display only when the content
//          has changed.
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
			uint32_t	wr03 : 4;	// /WR0..3 (LSB)
			uint32_t	led03 : 4;	// /LED0..3
			uint32_t	d3 : 1;		// D3
			uint32_t	d2 : 1;		// D2
			uint32_t	d1 : 1;
			uint32_t	d0 : 1;
			uint32_t	led47 : 4;	// /LED4..7
			uint32_t	d5 : 1;		// D5
			uint32_t	d4 : 1;		// D4
			uint32_t	a1 : 1;		// A1
			uint32_t	a0 : 1;		// A0
			uint32_t	wr47 : 4;	// /WR4..7
			uint32_t	d6 : 1;		// D6
			uint32_t	fill : 7;	// MSB
		} sr;
	} u;
	unsigned	leds;		// Saved LED settings
	union 	{
		unsigned indata;
		struct { 		// Input order
			unsigned pb4 : 1;
			unsigned pb3 : 1;
			unsigned pb2 : 1;
			unsigned pb1 : 1;
			unsigned pb7 : 1;
			unsigned pb6 : 1;
			unsigned pb5 : 1;
			unsigned pb0 : 1;
			unsigned fill : 8;
		} sr;
	} pb;
	unsigned	pbdata;		// Input push button data

protected:
	void write_cmd(uint32_t cmd);           // Internal

public:	DLG_1414();
	void writec(unsigned char c,unsigned digit);	// Write character
	unsigned read(bool strobe=true);	// Read pushbuttons
	bool set_led(bool b,unsigned led);	// Set one LED
	unsigned get_buttons() { return pbdata; }
};
	
//////////////////////////////////////////////////////////////////////
// DLG_1414 Constructor
//////////////////////////////////////////////////////////////////////

DLG_1414::DLG_1414() {
	DDRD |= _BV(CP)|_BV(STR)|_BV(D); // outputs
	DDRD &= ~_BV(PBD);		// input
        PORTD &= ~(_BV(CP)|_BV(D));	// CP=1, D=1 
	PORTD |= _BV(STR);		// STR=1
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

	PORTD &= ~(_BV(CP)|_BV(STR)|_BV(D));

	// Send D6 first, so that at the end it is in IC3's Q7S output

	if ( (cmd & 0x1000000) != 0 )	 	// D6?
		PORTD |= _BV(D);		// D=1 (D6)
	PORTD |= _BV(CP);			// CP=1
	PORTD &= ~_BV(CP);			// CP=0

	for ( int x=0; x<24; ++x ) {
		d = (sr & (uint32_t(1) << 23)) ? 1 : 0;
		sr <<= 1;
		PORTD &= ~_BV(CP);		// CP=0
		if ( d )
			PORTD |= _BV(D);
		else	PORTD &= ~_BV(D);
		PORTD |= _BV(CP);		// CP=1
	}

	PORTD |= _BV(STR);			// STR=1
	PORTD &= ~_BV(CP);			// CP=0 (this also sets Q7S=QP7 for IC3)
}

//////////////////////////////////////////////////////////////////////
// Force read of push button data (must occur after STR set low)
//////////////////////////////////////////////////////////////////////

unsigned
DLG_1414::read(bool strobe) {
	int x;

	PORTD |= _BV(D);
	PORTD &= ~_BV(STR);
	pb.indata = 0;
	for ( x=0; x<8; ++x ) {
		pb.indata = (pb.indata << 1) | !(PIND & _BV(PBD));
		PORTD |= _BV(CP);
		PORTD &= ~_BV(CP);
	}

	write_cmd(u.cmd);

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
DLG_1414::writec(unsigned char c,unsigned digit) {
	uint8_t uc = uint8_t(c);	// Unsigned char
	unsigned m = digit >> 2;	// Module select 0..7
	uint8_t d = (uint8_t(digit) & 3u) ^ 3; // Digit 0..3
	uint32_t msel;			// Module select /WR=1

	if ( m <= 3 )
		msel = (1 << m);	// First group
	else 	msel = (uint32_t(1) << uint32_t(m-4)) << 20;

	u.cmd = 0;
	u.sr.wr03 = u.sr.wr47 = 0x0F;	// all /WR=1

	// Maintain existing LED status
	u.sr.led03 = (leds & 0x0F) ^ 0x0F;
	u.sr.led47 = ((leds >> 4) & 0x0F) ^ 0x0F;

	u.sr.a0 = !!(d & 1);		// A0
	u.sr.a1 = !!(d & 2);		// A1
	u.sr.d0 = !!(uc & 0x01);	// D0 ..
	u.sr.d1 = !!(uc & 0x02);
	u.sr.d2 = !!(uc & 0x04);
	u.sr.d3 = !!(uc & 0x08);
	u.sr.d4 = !!(uc & 0x10);
	u.sr.d5 = !!(uc & 0x20);
	u.sr.d6 = !!(uc & 0x40);	// D6

	write_cmd(u.cmd);		// /WR=1, stabilize A1,A0
	write_cmd(u.cmd^msel);		// /WR=0
	write_cmd(u.cmd);		// /WR=1
	read(false);
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
		u.sr.led03 = (leds & 0x0F) ^ 0x0F;
		u.sr.led47 = ((leds >> 4) & 0x0F) ^ 0x0F;
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
	char c;			// Character to display
	unsigned dx;		// Digit index
	uint8_t pb, ppb = 0;	// PB data, prev PB data
	uint8_t delta;		// Changes in PB data

#if 0
	for (;;) {
		for ( c = 0x00; c<0x80; ) {
			// Display 8 modules (8x4 characters)
			for ( dx=0; dx<32; ++dx ) {
				dlg1414.writec(c,dx);
				++c;
			}
			_delay_ms(800);
		}
		_delay_ms(800);
	}
#endif

	c = 'A';
	for ( dx=0; dx<32; ++dx ) {
		dlg1414.writec(c,dx);
		++c;
	}

	for (;;) {
		pb = dlg1414.read();	// Read pb
		delta = ppb ^ pb;	// Note changes
		ppb = pb;		// Save for next loop

		for ( int x=0; x<8; ++x ) {
			if ( delta & 1 ) { // PB changed?
				if ( pb & 1 )
					c = 'a';
				else	c = 'A';
				dlg1414.writec(c+x,x);
				dlg1414.set_led(pb & 1,x);
			}
			pb >>= 1;
			delta >>= 1;
		}
		_delay_ms(1);
	}

	return 0;
}

// End dlg1414.cpp
