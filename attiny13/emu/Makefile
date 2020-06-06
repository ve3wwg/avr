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
	$(CC) -x assembler-with-cpp -c -nostdlib $(DEFNS) $< -o $@

.c.s:
	$(CC) -S $< -o $@

.elf.hex:
	@rm -f $*.hex
	avr-objcopy -j .text -j .data -O ihex $< $@
	avr-size --format=avr --mcu=$(DEVICE) $<
	avr-objdump -D emu.elf

all:	emu.hex

emu.elf: emu.o
	$(CC) emu.o -nostdlib -o emu.elf

emu.o: Makefile emu.S

flash:	all
	$(AVRDUDE) -U flash:w:firefly.hex:i

#fuse:
#	$(AVRDUDE) $(FUSES)

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o firefly.vcd
	rm -f .simavr_pid sim.out firefly.vcd

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t

disasm:	emu.elf
	avr-objdump -d emu.elf

backup: clobber
	cd .. && tar -cvzHf firefly.tar.gz --exclude include firefly

#
#	Debug with simavr
#
gdb:	firefly.elf
	simavr -g -f 8000000 -m attiny13a firefly.elf 1>sim.out 2>&1 & echo $$! >.simavr_pid
	@ps -fp $$(cat .simavr_pid)
	@sleep 3
	avr-gdb -x gdb.simavr
	@kill $$(cat .simavr_pid)

#
#	Simulate firefly without using avr-gdb
#
trace:	firefly_trace.elf
	simavr firefly_trace.elf

# End
