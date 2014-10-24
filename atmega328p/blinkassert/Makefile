######################################################################
#  blinkassert library facility for ATmega328p 
#  Fri Oct 17 23:22:31 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

F_CPU	?= 4000000UL
DEVICE	?= atmega328p

PGBAUD  	= 115200
PGMBOARDUINO 	= -c arduino -P /dev/tty.usbserial-A6005XBY -B $(PGBAUD)

BOARDUINO	= avrdude $(PGMBOARDUINO) -p atmega328p

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DF_CPU=$(F_CPU)
COPTS	   = $(OPTZ)

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(PRGDEV)

CC	= avr-gcc -Wall $(OPTZ) -mmcu=$(DEVICE)
AS	= avr-as

.c.o:
	$(CC) -c $(COPTS) $< -o $@

.S.o:
	$(CC) -x assembler-with-cpp -c -g $(DEFNS) $< -o $@ -Wa,-a=$*.list

.c.s:
	$(CC) -S $< -o $@

.elf.hex:
	@rm -f $*.hex
	avr-objcopy -j .text -j .data -O ihex $< $@
	avr-size --format=avr --mcu=$(DEVICE) $<

OBJS	= blinkassert.o testmain.o

all:	blinkassert.o testmain.hex

testmain.elf: $(OBJS)
	$(CC) $(OBJS) -o testmain.elf

testmain.o: Makefile blinkassert.c blinkassert.h
blinkassert.o: Makefile blinkassert.h

flash:	testmain.hex
	$(BOARDUINO) -U flash:w:testmain.hex:i

readfuse:
	$(BOARDUINO) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

disasm:	testmain.elf
	avr-objdump -d testmain.elf

# End
