# MCU := atmega8
# MCU := atmega169
MCU := atmega328p

ADA_TARGETS := midi_test
GPR := midi.gpr

AR	= avr-ar
ADA	= avr-gnatmake
OCP	= avr-objcopy

# Optimization level, can be [0, 1, 2, 3, s]. 
#     0 = turn off optimization. s = optimize for size.
#     (Note: 3 is not always the best optimization level. See avr-libc FAQ.)
# Setting OPT here overrides the setting in the GPR file for Ada.
OPT = s

# MFLAGS = -O$(OPT) -XMCU=$(MCU) -P$(GPR) --RTS=$(ADA_RTS)
MFLAGS = -O$(OPT) -p -XMCU=$(MCU) -gnaty0 -gnaty-rb

all:	lib obj libmidi.a

libmidi.a: src/midi-receiver.adb src/midi-receiver.ads src/midi-transmitter.adb src/midi-transmitter.ads \
	   src/midi.adb src/midi.ads
	$(ADA) $(MFLAGS) -Pmidi_lib.gpr

test:	midi_test.gpr midi_test.adb
	$(ADA) $(MFLAGS) -aI./src -aL./lib -Pmidi_test.gpr -largs -L./lib -lmidi
	$(OCP) -O ihex -R .eeprom midi_test.elf midi_test.hex
	rm midi_test.elf

lib:	
	mkdir ./lib

obj:
	mkdir ./obj

clean:
	rm -f *.hex *.eep *.elf *.map *.sym *.lss *.ali b~*.ad? *.o
	rm -f errs.t 

clobber: clean
	rm -fr ./obj ./lib
	rm -f *.map lib/libmidi.a lib/*.ali lib/*.o

burn:	midi_test.hex
	$(AVRDUDE) -c arduino -p atmega328p -P $(PORT) -b 115200 -U flash:w:midi_test.hex

# End
