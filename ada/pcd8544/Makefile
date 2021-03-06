BURNMCU=m328p
MCU := atmega328p

AR	= avr-ar
ADA	= avr-gnatmake
OCP	= avr-objcopy

# Optimization level, can be [0, 1, 2, 3, s]. 
#     0 = turn off optimization. s = optimize for size.
#     (Note: 3 is not always the best optimization level. See avr-libc FAQ.)
# Setting OPT here overrides the setting in the GPR file for Ada.

OPT = s

MFLAGS = -O$(OPT) -p -XMCU=$(MCU) -gnaty0 -gnaty-rb

all:	lib obj lib/libpcd8544.a

lib/libpcd8544.a: lib obj
	$(ADA) $(MFLAGS) -Pbuild.gpr
	@echo "Do 'make test' to build test program"

test:	lib/libpcd8544.a test.gpr testmain.adb test_io.ads test_io.adb
	$(ADA) $(MFLAGS) -aI./src -aL./lib -Ptest.gpr
	$(OCP) -O ihex -R .eeprom testmain.elf testmain.hex
	@rm -f testmain.elf testmain.map testmain.ali b~* testmain.o

lib:	
	mkdir ./lib

obj:
	mkdir ./obj

clean:
	rm -f *.hex *.eep *.elf *.map *.sym *.lss *.ali b~*.ad? *.o
	rm -f errs.t 

libclean:
	rm -f *.elf *.map test_main.ali *.o *.ali
	rm -fr ./obj *.hex

clobber: clean
	rm -fr ./obj ./lib
	rm -f *.map lib/lib8544.a lib/*.ali lib/*.o

burn:	testmain.hex
	avrdude $(PGMPARMS) -p $(BURNMCU) -U flash:w:testmain.hex

include ../avrdude.mk

# End
