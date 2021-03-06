######################################################################
#  Assembler bassert macro for ATtinyX
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

PGMAVR = -c usbasp -F -B 1

# PGBAUD  = 115200
# PGMBOARDUINO = -c arduino -P /dev/tty.usbserial-A6005XBY -B $(PGBAUD)
# PROGRAMMER = $(PGMBOARDUINO)

PROGRAMMER = $(PGMAVR)

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DF_CPU=$(F_CPU) $(NDEBUG)
COPTS	   = $(OPTZ)

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)

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

OBJ	= testmain.o

all:	testmain.hex 

testmain.elf: $(OBJ)
	$(CC) $(OBJ) -o testmain.elf

testmain.o: Makefile testmain.S bassert.h

flash:	testmain.hex
	$(AVRDUDE) -U flash:w:testmain.hex:i

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

disasm:	testmain.elf
	avr-objdump -d testmain.elf

# End
