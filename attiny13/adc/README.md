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

    Program:     100 bytes (9.8% Full)
    (.text + .data + .bootloader)
    
    Data:          0 bytes (0.0% Full)
    (.data + .bss + .noinit)

Example 2:

    Example 2 uses the ADC in "free running" mode. Example 1 starts
    the ADC as part of the main loop. Example 2 starts the ADC once
    immediately after configuration. From that point on, it only has 
    to check for completion from that point forward.

    Program:     108 bytes (10.5% Full)
    (.text + .data + .bootloader)
    
    Data:          0 bytes (0.0% Full)
    (.data + .bss + .noinit)

Example 3:

    Example 3 expands on example 2, by making it interrupt driven.
    The interrupt service routine reads the ADC result and deposits
    the ADC result into SRAM. The ISR also sets a flag in SRAM to
    signal to the main program that a new conversion result is 
    available. The main program then only has to check the SRAM
    flag and display the saved ADC value when the flag is set.

    Program:     152 bytes (14.8% Full)
    (.text + .data + .bootloader)
    
    Data:          2 bytes (3.1% Full)
    (.data + .bss + .noinit)

Example 4:

    Example 4 builds further on example 3, by using Timer/Counter0
    to trigger the interrupt driven ADC. Timer 0 is configured to
    interrupt in CTC mode, interrupting when Output Compare Count A
    matches. While the Timer 0 ISR is not used, it is coded as an
    example. Timer 0 Output Compare A simultaneously starts the
    ADC peripheral, resulting in precise interval measurements,
    which are displayed on the LEDs in the main loop.
    
    Program:     192 bytes (18.8% Full)
    (.text + .data + .bootloader)
    
    Data:          2 bytes (3.1% Full)
    (.data + .bss + .noinit)


Example 5:

    This example builds upon example 4 by adding a watchdog timer.
    The watchdog timer is implemented as a two stage watchdog:

     1) First timeout: Interrupts after the first timeout occurs 
        (lighting all LEDs as a warning)
     2) Second timeout: Resets the MCU (LEDs go dark briefly)

    As long as the control (potentiometer) keeps changing sometime
    within the 4 second timeout window, no watchdog timeout
    interrupt or MCU reset occurs. The first timeout causes all
    LEDs to light as a pending warning of reset. If the next 4
    seconds expire without a control change, then the watchdog
    timer forces a MCU reset (the LEDs will go dark briefly during
    this time).

    Program:     244 bytes (23.8% Full)
    (.text + .data + .bootloader)
    
    Data:          4 bytes (6.2% Full)
    (.data + .bss + .noinit)

