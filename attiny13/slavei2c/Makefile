######################################################################
#  Assembler bassert macro for ATtinyX
#  Wed Oct 22 21:39:02 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include ../Makefile.programmer

DEVICE	?= attiny13a
PDEV	?= t13
F_CPU	?= 8000000	
NDEBUG	?= 0

ifneq	($(NDEBUG),0)
NDEBUG	= -DNDEBUG
else
NDEBUG	=
endif

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DF_CPU=$(F_CPU) $(NDEBUG)
COPTS	   = $(OPTZ)

.SUFFIXES: .hex .elf

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

OBJ	= slavei2c.o application.o

all:	slavei2c.hex 

slavei2c.elf: $(OBJ)
	$(CC) $(OBJ) -o slavei2c.elf

slavei2c.o: Makefile slavei2c.S

flash:	slavei2c.hex
	$(AVRDUDE) -p $(PDEV) -U flash:w:slavei2c.hex:i

readfuse:
	$(AVRDUDE) -p $(PDEV) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex sim.out .errs.t *.list 

disasm:	slavei2c.elf
	avr-objdump -d slavei2c.elf

#
#       Debug with simavr
#
gdb:    slavei2c.elf
	simavr -g -f 8000000 -m attiny13a slavei2c.elf 1>sim.out 2>&1 & echo $$! >.simavr_pid
	 @ps -fp $$(cat .simavr_pid)
#       @sleep 4
	avr-gdb -x gdb.simavr
	@kill $$(cat .simavr_pid)

# End
