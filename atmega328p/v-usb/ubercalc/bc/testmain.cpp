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
	BC A, B, C;
	bc_num a, b, c, q, r;

	bc_init_numbers();	// Not required if BC constructor happens first

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

	A.assign("4501.9",10);
	A.dump("A:");

	B.assign("98.007");
	B.dump("B:");

	C = A * B;
	C.dump("C:");

	BC D, Two("2");

	D = C / Two;
	D.dump("C/2:");	

	BC M, E;

	E = D / B;
	M = D % B;

	E.dump("D/B:");
	M.dump("D%B:");

	E = B ^ Two;
	E.dump("B^2:");

	BC Nine("9.0009"), N99(99);
	Nine.dump("Nine:");	
	N99.dump("N99:");

	printf("Nine = %ld (as a long)\n",Nine.as_long());

	BC N22(22), N7(7), NQ, NR;

	NQ = N22.divmod(N7,NR,3);
	NQ.dump("NQ:");
	NR.dump("NR:");

	NQ = N22.div(N7,4);
	NQ.dump("NQ:");
	printf("NQ.scale = %d\n",NQ.scale());

	BC N8(8), N2(2), N10(10);

	NR = N8.raisemod(N2,N10,0);
	NR.dump("raisemod:");

	BC Zero(0);
	printf("Zero = %d\n",!Zero);

	BC Nearly("0.001");

	for ( int sc = 0; sc<5; ++sc )
		printf("0.001 near_zero(%d) => %d\n",sc,Nearly.is_near_zero(sc));

	Nearly.assign("0.002");
	for ( int sc = 0; sc<5; ++sc )
		printf("0.002 near_zero(%d) => %d\n",sc,Nearly.is_near_zero(sc));

	BC Big(9), Same(9), Small(8);

	assert(Big > Small);
	assert(Big >= Small);
	assert(Big >= Same);
	assert(Big == Same);
	assert(Big != Small);
	assert(Small < Big);
	assert(Same <= Big);

	BC Neg("-65.04");
	Neg.dump("Neg:");

	assert(Neg.is_negative());

	N8.dump("N8:");
	N8 = N8.negate();
	N8.dump("-N8:");

	BC::zero().dump("0:");
	BC::one().dump("1:");
	BC::two().dump("2:");

	bc_free_num(&a);
	bc_free_num(&b);
	bc_free_num(&c);
	bc_free_num(&q);
	bc_free_num(&r);
	}

	{
		BC s, piby4(".7853");
		BC x(piby4,30);

		x.dump("x:");

		s = BC::sin(x,30);
		s.dump("sin(x):");
	
		BC c = BC::cos(x,30);
		c.dump("cos(x):");

		BC e = BC::e(BC(1),30);
		e.dump("e:");
	}

	if ( bc_valgrind )
		bc_fini_numbers();		// Not required, except for valgrind testing

	return 0;
}

// End testmain.cpp
