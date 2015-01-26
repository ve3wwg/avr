######################################################################
#  ATtinyX Push Button Project
#  Wed Oct 22 21:39:02 2014	Warren W. Gay VE3WWG
#  LICENSE: GPL
######################################################################

include Makefile.incl

all:	test2

test2:	test2.o
	$(CXX) test2.o -o test2 $(LDFLAGS)

clean:
	rm -f *.o

clobber: clean
	rm -f .errs.t test2

# End
