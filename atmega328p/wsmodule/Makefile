######################################################################
#  blinkassert library facility for ATmega328p 
#  Fri Oct 17 23:22:31 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include ../Makefile.programmer

F_CPU	?= 4000000UL
DEVICE	?= atmega328p
PRGDEV	?= m328p

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DF_CPU=$(F_CPU)
COPTS	   = $(OPTZ)

.SUFFIXES: .hex .elf

PROGRAMMER = $(AVRDUDE) -p $(PRGDEV)

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

OBJS	= wsmodule.o

all:	wsmodule.hex

wsmodule.elf: $(OBJS)
	$(CC) $(OBJS) -o wsmodule.elf

flash:	wsmodule.hex
	$(PROGRAMMER) -U flash:w:wsmodule.hex:i

readfuse:
	$(PROGRAMMER) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

disasm:	testmain.elf
	avr-objdump -d testmain.elf

# End
