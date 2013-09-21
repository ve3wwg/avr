#MCU=avr5
# RTS=rts/avr51
MCU=atmega168

OPTZ	= -Os

all: blinky.hex
	
blinky.hex: Makefile
	avr-gnatmake $(OPTZ) -XMCU=$(MCU) -Pblinky.gpr -largs -M
	avr-size -C --mcu=$(MCU) blinky.elf
	avr-objcopy -O ihex blinky.elf blinky.hex

dump:
	avr-objdump -mavr:5 -d blinky.elf

size:	blinky.hex blinky.elf
	avr-size -C --mcu=$(MCU) blinky.elf

clean:
	rm -f b~*.ad[sb] *.o *.ali *.ihex blinky.elf

clobber: clean
	rm -f *.elf *.hex errs.t *.dump *.bin *.map

burn:
	avrdude $(PGMPARMS) -v -v -p m168 -F -U flash:w:blinky.hex

read:
	avrdude $(PGMPARMS) -v -v -p m168 -F -U flash:r:"read.bin":r

include ../avrdude.mk

# End
