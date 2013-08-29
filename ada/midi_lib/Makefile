# MCU := atmega8
# MCU := atmega169
MCU := atmega328p

ADA_TARGETS := midi_test
GPR := midi.gpr

# Optimization level, can be [0, 1, 2, 3, s]. 
#     0 = turn off optimization. s = optimize for size.
#     (Note: 3 is not always the best optimization level. See avr-libc FAQ.)
# Setting OPT here overrides the setting in the GPR file for Ada.
OPT = s

# MFLAGS = -O$(OPT) -XMCU=$(MCU) -P$(GPR) --RTS=$(ADA_RTS)
MFLAGS = -O$(OPT) -p -XMCU=$(MCU) -gnaty0 -gnaty-rb -Pmidi_lib.gpr

all:	midi_test

midi_test:
	avr-gnatmake $(MFLAGS) midi_test.adb

clean:
	rm -f *.hex *.eep *.elf *.map *.sym *.lss *.ali b~*.ad? *.o
	rm -f errs.t 

clobber: clean
	rm -f *.map
