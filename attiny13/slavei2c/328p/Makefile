######################################################################
#  blinkassert library facility for ATmega328p 
#  Fri Oct 17 23:22:31 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include ../../../atmega328p/Makefile.programmer

F_CPU	?= 4000000UL
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

OBJS	= testi2c.o i2cmaster.o

all:	testi2c.hex

testi2c.elf: $(OBJS)
	$(CXX) $(OBJS) -o testi2c.elf

flash:	testi2c.hex
	$(AVRDUDE) -p $(DEVICE) -U flash:w:testi2c.hex:i

readfuse:
	$(AVRDUDE) -p $(DEVICE) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	rm -f *.o

clobber: clean
	rm -f *.elf *.hex simul.out .errs.t *.list

disasm:	testi2c.elf
	avr-objdump -d testi2c.elf

# End
