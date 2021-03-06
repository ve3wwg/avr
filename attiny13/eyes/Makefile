######################################################################
#  ATtinyX Push Button Project
#  Wed Oct 22 21:39:02 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

DEVICE	?= attiny13a
F_CPU	?= 8000000	

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
DEFNS	   = -DF_CPU=$(F_CPU)
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

all:	eyes.hex

eyes.elf: eyes.o
	$(CC) eyes.o -o eyes.elf

eyes.o: Makefile

#
# Flash the device without setting the fuse bytes. Use this for experimenting
#
flash:	eyes.hex
	$(AVRDUDE) -U flash:w:eyes.hex:i 

#
# Use this prior to building. This flash sets the fuse bits so that the /RESET
# input is an I/O pin. This allows the software to use an internal pullup 
# resistor, so that no external one is required. This will effectively "brick"
# the device, unless you have a 12V programmer (or the "debricker")
#
finalflash: eyes.hex
	$(AVRDUDE) -U flash:w:eyes.hex:i -U lfuse:w:0x6a:m -U hfuse:w:0xfe:m

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

# End
