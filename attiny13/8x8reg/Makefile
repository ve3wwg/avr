######################################################################
#  8x8reg Debug Display Matrix Project for ATtiny13A
#  Sat Sep  6 15:11:41 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

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

PGBAUD     = 115200

PROGRAMMER = -c usbasp -F -B 1

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DSIM=$(SIM)
COPTS	   = $(OPTZ)

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(PRGDEV)

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

OBJ	= 8x8rx.o 

all:	8x8reg.hex 

8x8reg.elf: $(OBJ)
	$(CC) $(OBJ) -o 8x8reg.elf

8x8reg.o: Makefile 8x8reg.S

flash:	8x8reg.hex
	$(AVRDUDE) -U flash:w:8x8reg.hex:i

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

gdb::	sim.elf
	simulavr -g -d $(SIMDEV) sim.elf 1>simul.out 2>&1 & echo $$! >simulavr.pid
	avr-gdb
	@ps -fp $$(cat simulavr.pid)
	kill $$(cat simulavr.pid)
	@rm -f simulavr.pid simul.out

# End
