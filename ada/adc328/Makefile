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

MFLAGS = -O$(OPT) -p -XMCU=$(MCU)

all:	lib/libadc328.a

lib/libadc328.a: lib obj build.gpr
	$(ADA) $(MFLAGS) -Pbuild.gpr 

dump:
	avr-objdump -mavr:5 -d main.elf

test:	lib/libadc328.a test.gpr main.adb test.ads test.adb
	$(ADA) $(MFLAGS) -Ptest.gpr
	avr-size -C --mcu=$(MCU) main.elf
	$(OCP) -O ihex -R .eeprom main.elf main.hex

size:	main.elf
	avr-size -C --mcu=$(MCU) main.elf

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

burn:	main.hex
	avrdude $(PGMPARMS) -p $(BURNMCU) -U flash:w:main.hex

cu:	
	putty -load boarduino &

lib/libtwi.a: ./src/twi.ads ./src/twi.adb Makefile

include ../avrdude.mk

# End
