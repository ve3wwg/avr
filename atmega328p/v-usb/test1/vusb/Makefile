######################################################################
# Makefile for V-USB Subdir
######################################################################

include ../Makefile.incl

all:	libvusb.a

OBJS	= usbdrv.o oddebug.o usbdrvasm.o

libvusb.a: $(OBJS)
	@rm -f libvusb.a
	$(AR) r libvusb.a $(OBJS)
	@ls -l libvusb.a

clean:
	rm -f *.o

clobber: clean
	rm -f *.a *.elf *.hex simul.out .errs.t *.list

# End
