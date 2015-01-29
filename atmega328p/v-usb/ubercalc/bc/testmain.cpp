//////////////////////////////////////////////////////////////////////
// testmain.cpp -- Test Main for bc math lib
// Date: Thu Jan 29 08:35:05 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <assert.h>

#include "number.hpp"

extern "C" {

void
rt_warn(const char *msg,...) {
	va_list ap;

	fputs("WARNING: ",stdout);

	va_start(ap,msg);
	vprintf(msg,ap);
	va_end(ap);
}

void
rt_error(const char *msg,...) {
	va_list ap;

	fputs("ERROR: ",stderr);

	va_start(ap,msg);
	vfprintf(stderr,msg,ap);
	va_end(ap);
}

void
out_of_memory() {
	puts("OUT OF MEMORY!");
	exit(1);
}

} // extern "C"

static void
out_dig(int dig) {
	putchar(dig);
}

int
main(int argc,char **argv) {
	bc_num a, b, c;

	bc_init_numbers();

	bc_init_num(&a);
	bc_init_num(&b);
	bc_init_num(&c);

	bc_str2num(&a,"23.5",6);
	bc_str2num(&b,"12.01",6);
	bc_add(a,b,&c,6);

	bc_out_num(c,10,out_dig,0);	
	putchar('\n');

	return 0;
}

// End testmain.cpp
