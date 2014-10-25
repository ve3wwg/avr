ADC
---

This directory contains experiments using the ATtiny13A ADC.

Example 1:

    Example 1 continuously starts the ADC and polls the results, from it
    upon completion. Then the 4 most significant bits are then displayed
    on LEDs wired to PB3..PB0. 

    The 10k potentiometer's wiper is connected to ADC input PB4 (ADC2).
    The other ends of the pot are connected to VCC and GND of course.

    Turning the pot from off to full on, will cycle the LEDs from 
    displaying the value zero (all off) to 0xF (all on).

