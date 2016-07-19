######################################################################
#  blinkassert library facility for ATmega328p 
#  Fri Oct 17 23:22:31 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include ../../atmega328p/Makefile.programmer

F_CPU	?= 1000000UL
DEVICE	?= atmega32
PRGDEV	?= m32

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

OBJS	= kbscan.o

all:	kbscan.hex

kbscan.elf: $(OBJS)
	$(CC) $(OBJS) -o kbscan.elf

flash:	kbscan.hex
	$(PROGRAMMER) -U flash:w:kbscan.hex:i

readfuse:
	$(PROGRAMMER) -F -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

signature:
	$(PROGRAMMER) -F -U signature:r:-:h

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

disasm:	testmain.elf
	avr-objdump -d testmain.elf

# End
