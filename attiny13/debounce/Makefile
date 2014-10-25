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

all:	simplepb1.hex simplepb2.hex togglepb3.hex togglepb4.hex

simplepb1.elf: simplepb1.o
	$(CC) simplepb1.o -o simplepb1.elf

simplepb2.elf: simplepb2.o
	$(CC) simplepb2.o -o simplepb2.elf

togglepb3.elf: togglepb3.o
	$(CC) togglepb3.o -o togglepb3.elf

togglepb4.elf: togglepb4.o
	$(CC) togglepb4.o -o togglepb4.elf

simplepb1.o: Makefile
simplepb2.o: Makefile
togglepb3.o: Makefile
togglepb4.o: Makefile

flash-pb1: simplepb1.hex
	$(AVRDUDE) -U flash:w:simplepb1.hex:i

flash-pb2: simplepb2.hex
	$(AVRDUDE) -U flash:w:simplepb2.hex:i

flash-pb3: togglepb3.hex
	$(AVRDUDE) -U flash:w:togglepb3.hex:i

flash-pb4: togglepb4.hex
	$(AVRDUDE) -U flash:w:togglepb4.hex:i

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

# End
