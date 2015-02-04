######################################################################
#  Makefile
######################################################################

include Makefile.incl

all:	testmain

testmain: number.o testmain.o bcnum.o bf.o
	$(CXX) testmain.o number.o bcnum.o bf.o -o testmain -lm

clean:
	rm -f *.o *.core

clobber: clean
	@rm -f errs.t .errs.t
	rm -f testmain 

number.o: number.hpp
