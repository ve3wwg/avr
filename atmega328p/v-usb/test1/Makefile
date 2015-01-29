######################################################################
#  ATtinyX Push Button Project
#  Wed Oct 22 21:39:02 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include Makefile.incl
include ../../Makefile.programmer

PART	= atmega328p

all:	test1.hex test2.hex

test2.elf: vusb/libvusb.a test2.o
	$(CXX) test2.o -o test2.elf -L./vusb -lvusb

test1.elf: test1.o
	$(CXX) test1.o -o test1.elf

test1.o: Makefile
test2.o: Makefile

vusb/libvusb.a:
	$(MAKE) -$(MAKEFLAGS) -Cvusb all

flash1:	test1.hex
	$(AVRDUDE) -p $(PART) -vv -U flash:w:test1.hex:i

flash2: test2.hex
	$(AVRDUDE) -p $(PART) -U flash:w:test2.hex:i -U lfuse:w:0x5e:m -U hfuse:w:0xd9:m -U efuse:w:0xff:m
#                                                    -U lfuse:w:0x7f:m -U hfuse:w:0xd9:m -U efuse:w:0xff:m

readfuse:
	$(AVRDUDE) -p $(PART) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h -v

clean:
	$(MAKE) -$(MAKEFLAGS) -Cvusb clean
	rm -f *.o

clobber: clean
	$(MAKE) -$(MAKEFLAGS) -Cvusb clobber
	$(MAKE) -$(MAKEFLAGS) -Cposix clobber
	rm -f test1 test2
	rm -f *.elf *.hex .errs.t

# End
