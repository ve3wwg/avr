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

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(PRGDEV)

CC	= avr-gcc -Wall $(OPTZ) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)
CXX	= avr-g++ -Wall $(OPTZ) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)
AS	= avr-as

.c.o:
	$(CC) -c $< -o $@

.cpp.o:
	$(CXX) -c $(OPTS) $< -o $@

.S.o:
	$(CC) -x assembler-with-cpp -c -g $(DEFNS) $< -o $@

.c.s:
	$(CC) -S $< -o $@

.elf.hex:
	@rm -f $*.hex
	avr-objcopy -j .text -j .data -O ihex $< $@
	avr-size --format=avr --mcu=$(DEVICE) $<

all:	firefly.hex

firefly.elf: firefly.o
	$(CC) firefly.o -o firefly.elf

firefly.o: Makefile firefly.S

flash:	all
	$(AVRDUDE) -U flash:w:firefly.hex:i

#fuse:
#	$(AVRDUDE) $(FUSES)

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t

disasm:	firefly.elf
	avr-objdump -d firefly.elf

backup: clobber
	cd .. && tar -cvzHf firefly.tar.gz --exclude include firefly

gdb:	firefly.elf
	simulavr -g -d $(SIMDEV) firefly.elf 1>simul.out 2>&1 & echo $$! >simulavr.pid
	avr-gdb
	@ps -fp $$(cat simulavr.pid)
	kill $$(cat simulavr.pid)
	@rm -f simulavr.pid simul.out

# End
