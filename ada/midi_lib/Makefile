BURNMCU=m168
MCU := atmega168

AR	= avr-ar
ADA	= avr-gnatmake
OCP	= avr-objcopy

# Optimization level, can be [0, 1, 2, 3, s]. 
#     0 = turn off optimization. s = optimize for size.
#     (Note: 3 is not always the best optimization level. See avr-libc FAQ.)
# Setting OPT here overrides the setting in the GPR file for Ada.

OPT = s

MFLAGS = -O$(OPT) -p -XMCU=$(MCU) -gnaty0 -gnaty-rb

all:	lib obj libmidi.a

libmidi.a: src/midi-receiver.adb src/midi-receiver.ads src/midi-transmitter.adb src/midi-transmitter.ads \
	   src/midi.adb src/midi.ads
	$(ADA) $(MFLAGS) -Pbuild.gpr

test:	test.gpr midi_test.adb
	$(ADA) $(MFLAGS) -aI./src -aL./lib -Ptest.gpr 
	$(OCP) -O ihex -R .eeprom midi_test.elf midi_test.hex
	@rm -f midi_test.ali b~* midi_test.o

lib:	
	mkdir ./lib

obj:
	mkdir ./obj

clean:
	rm -f *.hex *.eep *.elf *.map *.sym *.lss *.ali b~*.ad? *.o
	rm -f errs.t 

libclean:
	rm -f *.elf *.map test_main.ali *.o 
	rm -fr ./obj *.hex

clobber: clean
	rm -fr ./obj ./lib *.elf *.map
	rm -f *.map lib/libmidi.a lib/*.ali lib/*.o

burn:	midi_test.hex
	avrdude $(PGMPARMS) -p $(BURNMCU) -U flash:w:midi_test.hex

include ../avrdude.mk

# End
