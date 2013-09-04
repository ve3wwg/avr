MCU=atmega168

include ../avrdude.mk

all:    synth

test:
	avr-gnatmake -XMCU=$(MCU) -Psynth.gpr -largs -M
	avr-objcopy -O ihex main.elf synth.hex
	avr-objdump -mavr:5 -d main.elf >synth.dump

synth:	
	make avr_all

burn:
	make avr_burn

read:
	make avr_read

backup:	mostly_clean
	( cd .. && tar czvf synth.tar.gz synth avrdude.mk )
	@ls -l ../synth.tar.gz

avr_all: clean synth.hex
	
synth.hex: Makefile
	avr-gnatmake -g -XMCU=$(MCU) -Psynth.gpr -largs -M
	avr-objcopy -O ihex main.elf synth.hex
	avr-objdump -mavr:5 -d main.elf >synth.dump

dump:
	avr avr-objdump -mavr:5 -d main.elf

clean:  mostly_clean
	rm -f *.hex *.dump

mostly_clean:
	rm -f b~*.ad[sb] *.o *.ali *.elf errs.t *.ly1
	rm -f *.stackdump *.exe

clobber: clean

avr_burn:
	avrdude $(PGMPARMS) -p m168 -F -U flash:w:synth.hex

avr_read:
	avrdude $(PGMPARMS) -p m168 -F -U flash:r:"read.bin":r

# End
