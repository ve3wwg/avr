debounce:
---------

This project is a short collection of ATtiny13A assembler programs showing the 
various aspects of working with a push button and LED (without interrupt
routines):

    1. Simplest possible button and LED example (simplepb1.S). This 
       provides a starting framework to develop further examples from.

    2. Simple button and LED toggle (with no debouncing - demonstrates
       the problem of contact bounce).

    3. Toggle LED with button presses, with debouncing (slow reaction).

    4. Toggle LED with button presses, with debouncing (fast acting).

INSTRUCTIONS:

    $ make

will compile all hex files (some Makefile adjustment may be required for your
AVR programmer).

    $ make flash-pb1 

will flash simplepb1.S, while:

    $ make flash-pb4

will flash togglepb4.S etc.
