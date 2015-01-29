######################################################################
#  ATtinyX Push Button Project
#  Wed Oct 22 21:39:02 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include Makefile.incl
include ../../Makefile.programmer

PART	= atmega328p

all:	test1.hex

test1.elf: test1.o
	$(CXX) test1.o -o test1.elf

test1.o: Makefile

#flash1:	test1.hex
#	$(AVRDUDE) -p $(PART) -vv -U flash:w:test1.hex:i

BAUD	?= 115200

readfuse:
	$(AVRDUDE) -c arduino -p $(PART) -b $(BAUD) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	$(MAKE) -$(MAKEFLAGS) -Cvusb clean
	rm -f *.o

clobber: clean
	$(MAKE) -$(MAKEFLAGS) -Cvusb clobber
	rm -f test1 test2
	rm -f *.elf *.hex .errs.t

# End
