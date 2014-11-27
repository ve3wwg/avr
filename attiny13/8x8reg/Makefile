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

F_CPU	?= 8000000

PRGDEV	?= $(DEVICE)

PGBAUD     = 115200

PROGRAMMER = -c usbasp -F -B 1

OPTZ	= -Os -g
INCL	= -I/usr/local/include/simavr
DEFNS	= -DF_CPU=$(F_CPU)
COPTS	= $(OPTZ) $(DEFNS) $(INCL)
TRACE	= -Wl,--undefined=_mmcu,--section-start=.mmcu=0x910000

.SUFFIXES: .hex .elf

AVRDUDE = avrdude $(PROGRAMMER) -p $(PRGDEV)

CC	= avr-gcc -Wall $(OPTZ) -mmcu=$(DEVICE)
AS	= avr-as

.c.o:
	$(CC) -c $(COPTS) $< -o $@

.S.o:
	$(CC) -x assembler-with-cpp -c $(COPTS) $< -o $@ -Wa,-a=$*.list

.c.s:
	$(CC) -S $< -o $@

.elf.hex:
	@rm -f $*.hex
	avr-objcopy -j .text -j .data -O ihex $< $@
	avr-size --format=avr --mcu=$(DEVICE) $<

OBJ	= 8x8rx.o 

all:	8x8reg.hex test13.hex

8x8reg.elf: $(OBJ)
	$(CC) $(OBJ) -o 8x8reg.elf

8x8reg.o: Makefile 8x8reg.S

flash:	8x8reg.hex
	$(AVRDUDE) -U flash:w:8x8reg.hex:i

test13.elf: test13.o tx8x8.o trace.o
	$(CC) $(TRACE) test13.o tx8x8.o trace.o -o test13.elf

flashtest: test13.hex
	$(AVRDUDE) -U flash:w:test13.hex:i

#fuse:
#	$(AVRDUDE) $(FUSES)

readfuse:
	$(AVRDUDE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list .simavr_pid .sim.out

disasm:	8x8reg.elf
	avr-objdump -d 8x8reg.elf

#
#	Debug with simavr
#
gdb:	test13.elf
	simavr -g -f 8000000 -m attiny13a test13.elf 1>sim.out 2>&1 & echo $$! >.simavr_pid
	@ps -fp $$(cat .simavr_pid)
#	@sleep 4
	avr-gdb -x gdb.simavr
	@kill $$(cat .simavr_pid)

# End
