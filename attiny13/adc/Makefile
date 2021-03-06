######################################################################
#  ATtinyX Push Button Project
#  Wed Oct 22 21:39:02 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

DEVICE	?= attiny13a
F_CPU	?= 8000000	
NDEBUG	?= 0

ifneq	($(NDEBUG),0)
NDEBUG	= -DNDEBUG
else
NDEBUG	=
endif

ifeq	($(DEVICE),attiny13a)
PGMDEV	= attiny13
else
PGMDEV	= $(DEVICE)
endif

PGMAVR = -c usbasp -F -B 1

# PGBAUD  = 115200
# PGMBOARDUINO = -c arduino -P /dev/tty.usbserial-A6005XBY -B $(PGBAUD)
# PROGRAMMER = $(PGMBOARDUINO)

PROGRAMMER = $(PGMAVR)

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DF_CPU=$(F_CPU) $(NDEBUG)
COPTS	   = $(OPTZ)

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(PGMDEV)

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

all:	example1.hex example2.hex example3.hex example4.hex example5.hex

example1.elf: example1.o
	$(CC) example1.o -o example1.elf

example2.elf: example2.o
	$(CC) example2.o -o example2.elf

example3.elf: example3.o
	$(CC) example3.o -o example3.elf

example4.elf: example4.o
	$(CC) example4.o -o example4.elf

example5.elf: example5.o
	$(CC) example5.o -o example5.elf

example1.o: Makefile
example2.o: Makefile
example3.o: Makefile
example4.o: Makefile
example5.o: Makefile

flash1:	example1.hex
	$(AVRDUDE) -U flash:w:example1.hex:i

flash2:	example2.hex
	$(AVRDUDE) -U flash:w:example2.hex:i

flash3:	example3.hex
	$(AVRDUDE) -U flash:w:example3.hex:i

flash4:	example4.hex
	$(AVRDUDE) -U flash:w:example4.hex:i

flash5:	example5.hex
	$(AVRDUDE) -U flash:w:example5.hex:i

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

# End
