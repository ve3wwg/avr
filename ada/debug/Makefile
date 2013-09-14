.SUFFIXES: .elf .hex

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

.elf.hex:
	$(OCP) -O ihex -R .eeprom $< $*.hex

all:	main.hex

main.elf: build.gpr main.adb
	$(ADA) $(MFLAGS) -Pbuild.gpr 

dump:
	avr-objdump -mavr:5 -d testmain.elf

clean:
	rm -f *.hex *.eep *.elf *.map *.sym *.lss *.ali b~*.ad? *.o
	rm -f errs.t

clobber: clean
	rm -f *.map 

burn:	main.hex
	avrdude $(PGMPARMS) -p $(BURNMCU) -U flash:w:main.hex

include ../avrdude.mk

main.elf: main.adb ttydbg.ads ttydbg.adb build.gpr Makefile

cu:	
	putty -load boarduino

# End
