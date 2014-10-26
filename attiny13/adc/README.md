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

Example 2:

    Example 2 uses the ADC in "free running" mode. Example 1 starts
    the ADC as part of the main loop. Example 2 starts the ADC once
    immediately after configuration. From that point on, it only has 
    to check for completion from that point forward.

Example 3:

    Example 3 expands on example 2, by making it interrupt driven.
    The interrupt service routine reads the ADC result and deposits
    the ADC result into SRAM. The ISR also sets a flag in SRAM to
    signal to the main program that a new conversion result is 
    available. The main program then only has to check the SRAM
    flag and display the saved ADC value when the flag is set.

Example 4:

    Example 4 builds further on example 3, by using Timer/Counter0
    to trigger the interrupt driven ADC. Timer 0 is configured to
    interrupt in CTC mode, interrupting when Output Compare Count A
    matches. While the Timer 0 ISR is not used, it is coded as an
    example. Timer 0 Output Compare A simultaneously starts the
    ADC peripheral, resulting in precise interval measurements,
    which are displayed on the LEDs in the main loop.
    
