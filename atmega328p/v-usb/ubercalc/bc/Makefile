######################################################################
#  Makefile
######################################################################

include Makefile.incl

all:	testmain

testmain: number.o testmain.o
	$(CXX) testmain.o number.o -o testmain -lm

clean:
	rm -f *.o *.core

clobber: clean
	rm -f testmain 

number.o: number.hpp
