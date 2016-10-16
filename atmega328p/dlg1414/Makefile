######################################################################
#  blinkassert library facility for ATmega328p 
#  Fri Oct 17 23:22:31 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include ../Makefile.programmer

# PGBAUD	= 57600

F_CPU	?= 1000000UL
DEVICE	?= atmega328p

OPTZ	   = -Os $(DEFNS)
DEFNS	   = -DF_CPU=$(F_CPU)

CFLAGS	   = -Wall $(OPTZ) -mmcu=$(DEVICE)
CXXFLAGS   = $(CFLAGS) -std=c++11
	
.SUFFIXES: .hex .elf

CXX	= avr-g++ $(CXXFLAGS)
AS	= avr-as

.cpp.o:
	$(CXX) -c $(COPTS) $< -o $@

.elf.hex:
	@rm -f $*.hex
	avr-objcopy -j .text -j .data -O ihex $< $@
	avr-size --format=avr --mcu=$(DEVICE) $<

OBJS	= dlg1414.o

all:	dlg1414.hex

dlg1414.elf: $(OBJS)
	$(CXX) $(OBJS) -o dlg1414.elf

flash:	dlg1414.hex
	$(USBASP) -p $(DEVICE) -U flash:w:dlg1414.hex:i -U lfuse:w:0x62:m -U hfuse:w:0xd9:m # -U efuse:w:0x07:m

readfuse:
	$(USBASP) -p $(DEVICE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

disasm:	dlg1414.elf
	avr-objdump -d dlg1414.elf

# End
