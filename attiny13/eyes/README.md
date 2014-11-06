eyes
----

This project drives two LEDs on PB0 and PB1 from an ATtiny13A (active
high). The watchdog timer is used so that this eye blink occurs once
every 64 seconds (approximately one minute). This should allow a 3V
CR2032 battery last about a year.

The eye blink itself is a fade from dark to bright, then remain bright
briefly  and then fade to black a little more slower.

The project was designed to drive LED eyes in an owl that hangs from the
living room wall.

