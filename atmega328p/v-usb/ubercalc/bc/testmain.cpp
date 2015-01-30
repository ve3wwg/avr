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

// #include "number.hpp"
#include "bcnum.hpp"

extern "C" {

void
bc_condition(bc_condition_t cond) {

	switch ( cond ) {
	case bc_cond_exponent_too_large:	// exponent too large
		fputs("bc: Exponent too large.\n",stderr);
		break;
	case bc_cond_nzero_base_scale:		// non-zero scale in base
		fputs("bc: Non-zero scale in base.\n",stderr);
		break;
	case bc_cond_nzero_exp_scale:		// non-zero scale in exponent
		fputs("bc: Non-zero scale in exponent.\n",stderr);
		break;
	case bc_cond_nzero_mod_scale:		// non-zero scale in modulus
		fputs("bc: Non-zero scale in modulus.\n",stderr);
		break;
	default :
		printf("Unknown bc_condition %d\n",cond);
		assert(0);
	}
}

void
bc_out_of_memory() {
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
	{
//	bc_valgrind = 1;
	BC_Num A, B, C;
	bc_num a, b, c, q, r;

	bc_init_numbers();	// Not required if BC_Num constructor happens first

	bc_init_num(&a);
	bc_init_num(&b);
	bc_init_num(&c);
	bc_init_num(&q);
	bc_init_num(&r);
	bc_str2num(&a,"23.5",6);
	bc_out_num(a,10,out_dig,0);	
	putchar('\n');

	bc_str2num(&b,"12.01",6);
	bc_add(a,b,&c,6);

	bc_out_num(c,10,out_dig,0);	
	putchar('\n');

	bc_str2num(&a,"10.00",6);
	bc_divide(c,a,&q,6);

	bc_out_num(q,10,out_dig,0);	
	putchar('\n');

	bc_multiply(q,a,&r,6);

	bc_out_num(r,10,out_dig,0);	
	putchar('\n');

	bc_str2num(&a,"2.0",10);
	bc_sqrt(&a,10);

	bc_out_num(a,10,out_dig,0);	
	putchar('\n');

	bc_str2num(&a,"10.0",10);
	bc_str2num(&b,"3.0",0);
	bc_raise(a,b,&c,15);
	bc_out_num(c,10,out_dig,0);	
	putchar('\n');

	A.set("4501.9",10);
	A.dump();

	B.set("98.007",3);
	B.dump();

	C = A + B;
	C.dump();

	bc_free_num(&a);
	bc_free_num(&b);
	bc_free_num(&c);
	bc_free_num(&q);
	bc_free_num(&r);
	}

	if ( bc_valgrind )
		bc_fini_numbers();		// Not required, except for valgrind testing

	return 0;
}

// End testmain.cpp
