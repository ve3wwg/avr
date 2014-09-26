######################################################################
#  8x8reg Debug Display Matrix Project for ATtiny13A
#  Sat Sep  6 15:11:41 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

#DEVICE	?= atmega328p
DEVICE	?= attiny13a

SIM	?= 0

ifeq ($(DEVICE),attiny13a)
PRGDEV	?= attiny13
endif

PRGDEV	?= $(DEVICE)

ifeq ($(SIM),1)
DEVICE = atmega128
SIMDEV = atmega128
PRGDEV = none
endif

CLOCK      = 8000000
PGBAUD     = 115200

PGMBOARDUINO = -c arduino -P /dev/tty.usbserial-A6005XBY -B $(PGBAUD)
PROGRAMMER = -c usbasp -F -B 1

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DSIM=$(SIM)

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(PRGDEV)
BOARDUINO = avrdude $(PGMBOARDUINO) -p atmega328p

CC	= avr-gcc -Wall $(OPTZ) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)
CXX	= avr-g++ -Wall $(OPTZ) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE)
AS	= avr-as

.c.o:
	$(CC) -c $< -o $@

.cpp.o:
	$(CXX) -c $(OPTS) $< -o $@

.S.o:
	$(CC) -x assembler-with-cpp -c -g $(DEFNS) $< -o $@ -Wa,-a=$*.list

.c.s:
	$(CC) -S $< -o $@

.elf.hex:
	@rm -f $*.hex
	avr-objcopy -j .text -j .data -O ihex $< $@
	avr-size --format=avr --mcu=$(DEVICE) $<

OBJ	= 8x8rx.o 
TOBJ	= testsend.o 

all:	8x8reg.hex # test

test:
	$(MAKE) $(MAKEFLAGS) testsend.hex DEVICE=atmega328p

8x8reg.elf: $(OBJ)
	$(CC) $(OBJ) -o 8x8reg.elf

testsend.elf: $(TOBJ)
	$(CC) $(TOBJ) -o testsend.elf

8x8reg.o: Makefile 8x8reg.S

testsend.o: Makefile testsend.S

sim.elf:: sim.o
	$(CC) sim.o -o sim.elf

flash:	8x8reg.hex
	$(AVRDUDE) -U flash:w:8x8reg.hex:i

flashtest: test
	$(BOARDUINO) -U flash:w:testsend.hex:i

#fuse:
#	$(AVRDUDE) $(FUSES)

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

disasm:	8x8reg.elf
	avr-objdump -d 8x8reg.elf

backup: clobber
	cd .. && tar -cvzHf 8x8reg.tar.gz --exclude include 8x8reg

gdb::	sim.elf
	simulavr -g -d $(SIMDEV) sim.elf 1>simul.out 2>&1 & echo $$! >simulavr.pid
	avr-gdb
	@ps -fp $$(cat simulavr.pid)
	kill $$(cat simulavr.pid)
	@rm -f simulavr.pid simul.out

# End
