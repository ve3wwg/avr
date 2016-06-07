This project implemented a digital module for a breadboard workstation.
Breadboard circuits often need debounced input signals for clocking
counters and shift registers.

This project implemented 4 cherry keyswitches with LED (shines through
the keycap). Each LED is driven by the debounced keyswitch inputs. In
addition, the software drives another 4 digital outputs D1-D4 that are 
completely isolated from the LEDs.

To provide low frequency oscillator sources, D1 and D2 can also be
pulsed outputs according to potentiometers P1 and P2. These are 
read through ADC0 and ADC1. When in the zero (counter-clockwise)
position, the D1/D2 output acts as a non-osc source. But turned
clockwise off of the zero position, D1/D2 will produce a 3 to 3kHz
pulse train, depending upon the pot position.

No crystal was used, but if you want a stabler osc output, one is
recommended.

The blink LED on PB1 was used for signs of life during development.

Keyswitch inputs:

	PB0 (D1 Key)
	PD7 (D2 Key)
	PD6 (D3 Key)
	PD5 (D4 Key)

Keyswitch LEDs (outputs):

	PD4 (D1 Key LED)
	PD3 (D2 Key LED)
	PD2 (D3 Key LED)
	PD1 (D4 Key LED)
	
TTL Signals Out:

	PB2 (D1)
	PB3 (D2)
	PB4 (D3)
	PB5 (D4)

Potentiometer inputs:

	D1 adjust ADC0
	D2 adjust ADC1

Potentiometer Wiring:

	CCW End: +Vcc
	Middle:	 ADCx
	CW End:	  Gnd

AVcc = Vcc

	PB1 (Blink LED)
