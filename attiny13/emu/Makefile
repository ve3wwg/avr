######################################################################
#  Firefly Jar Project for ATtiny13A
#  Sat Aug 30 23:32:11 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

DEVICE	?= attiny13a

ifeq ($(DEVICE),attiny13a)
PRGDEV	?= attiny13
endif

PRGDEV	?= $(DEVICE)

CLOCK      = 8000000
PGBAUD     = 115200

#PROGRAMMER = -c arduino -P /dev/tty.usbserial-A6005XBY -B $(PGBAUD)
PROGRAMMER = -c usbasp -F -B 1

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DSIM=$(SIM)

INCL	= -I/usr/local/include/simavr

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(PRGDEV)

CC	= avr-gcc -Wall $(OPTZ) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)
CXX	= avr-g++ -Wall $(OPTZ) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)
AS	= avr-as

.c.o:
	$(CC) $(INCL) -c $< -o $@

.cpp.o:
	$(CXX) -c $(OPTS) $< -o $@

.S.o:
	$(CC) -x assembler-with-cpp -c -Wa,-adhlns=$*.lst -nostdlib $(DEFNS) $< -o $@

.c.s:
	$(CC) -S $< -o $@

.elf.hex:
	@rm -f $*.hex
	avr-objcopy -j .text -j .data -O ihex $< $@
	avr-size --format=avr --mcu=$(DEVICE) $<
	@sed '1,/.section .text/d' <$*.lst >emu.l && mv emu.l $*.lst

.o.elf: 
	$(CC) $< -nostdlib -o $*.elf

all:	emu.hex emu2.hex

emu.o: Makefile emu.S
emu2.o: Makefile emu2.S

flash:	all
	$(AVRDUDE) -U flash:w:firefly.hex:i

#fuse:
#	$(AVRDUDE) $(FUSES)

#readfuse:
#	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o *.lst

clobber: clean
	rm -f *.elf *.hex .errs.t

# End
