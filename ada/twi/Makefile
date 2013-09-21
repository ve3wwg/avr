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

MFLAGS = -O$(OPT) -p -XMCU=$(MCU)

all:	lib obj lib/libtwi.a test

lib/libtwi.a: lib obj build.gpr
	$(ADA) $(MFLAGS) -Pbuild.gpr 
	@echo "Do 'make test' to build test program"

dump:
	avr-objdump -mavr:5 -d testmain.elf

test:	lib/libtwi.a test.gpr testmain.adb test_io.ads test_io.adb
	$(ADA) $(MFLAGS) -Ptest.gpr
	avr-size -C --mcu=$(MCU) testmain.elf
	$(OCP) -O ihex -R .eeprom testmain.elf testmain.hex

size:	testmain.elf
	avr-size -C --mcu=$(MCU) testmain.elf

lib:	
	mkdir ./lib

obj:
	mkdir ./obj

clean:
	rm -f *.hex *.eep *.elf *.map *.sym *.lss *.ali b~*.ad? *.o
	rm -f errs.t src/errs.t

libclean:
	rm -f *.elf *.map test_main.ali *.o *.ali
	rm -fr ./obj *.hex b~*

clobber: clean
	rm -fr ./obj ./lib
	rm -f *.map lib/lib8544.a lib/*.ali lib/*.o

burn:	testmain.hex
	avrdude $(PGMPARMS) -p $(BURNMCU) -U flash:w:testmain.hex

cu:	
	putty -load boarduino &

lib/libtwi.a: ./src/twi.ads ./src/twi.adb Makefile

include ../avrdude.mk

# End
