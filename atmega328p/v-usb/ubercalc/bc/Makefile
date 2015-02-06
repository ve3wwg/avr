######################################################################
#  Makefile
######################################################################

include Makefile.incl

all:	testmain

testmain: number.o testmain.o bc.o bf.o
	$(CXX) testmain.o number.o bc.o bf.o -o testmain -lm

clean:
	rm -f *.o *.core

clobber: clean
	@rm -f errs.t .errs.t
	rm -f testmain 

number.o: number.hpp
