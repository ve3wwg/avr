# MCU := atmega8
# MCU := atmega169
MCU := atmega328p

ADA_TARGETS := midi_test
GPR := midi.gpr

AR	= avr-ar
ADA	= avr-gnatmake

# Optimization level, can be [0, 1, 2, 3, s]. 
#     0 = turn off optimization. s = optimize for size.
#     (Note: 3 is not always the best optimization level. See avr-libc FAQ.)
# Setting OPT here overrides the setting in the GPR file for Ada.
OPT = s

# MFLAGS = -O$(OPT) -XMCU=$(MCU) -P$(GPR) --RTS=$(ADA_RTS)
MFLAGS = -O$(OPT) -p -XMCU=$(MCU) -gnaty0 -gnaty-rb

all:	libmidi.a

libmidi.a: midi-receiver.adb midi-receiver.ads midi-transmitter.adb midi-transmitter.ads midi.adb midi.ads
	$(ADA) $(MFLAGS) -Pmidi_lib.gpr

#	rm -f obj/*.o
#	rm -f midi_test.o b~midi_test.* midi_test.elf midi_test.ali
#	rm -f midi.o midi-receiver.o midi-transmitter.o
#	rm -f midi.ali midi-receiver.ali midi-transmitter.ali

test:	midi_test.gpr midi_test.adb
	$(ADA) $(MFLAGS) -aL./lib -Pmidi_test.gpr -largs -L./lib -lmidi

clean:
	rm -f *.hex *.eep *.elf *.map *.sym *.lss *.ali b~*.ad? *.o
	rm -f errs.t 

clobber: clean
	rm -fr obj
	mkdir ./obj
	rm -f *.map lib/libmidi.a lib/*.ali lib/*.o
