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

#include <string>
#include <sstream>

#include "bc.hpp"
#include "bf.hpp"

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
	case bc_cond_math_error:
		fputs("bc: Math error.\n",stderr);
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

#if 0
static void
out_dig(int dig,void *udata) {
	putchar(dig);
}
#endif

typedef BC (bcfunc_t)(const BC& x,int scale);

#if 0
static bool
test_fun(int from,int to,const char *incr,bcfunc_t func,int scale,const char *what,const char *bcfun) {
	char *cp = 0;
	char *xs = 0, *ys = 0;
	BC x(from), end(to), by(incr);

	if ( !strcmp(what,"ln") && from == 0 )
		x.assign("0.001");

	while ( x <= end ) {
		xs = x.as_string();
		printf("%s(%s) => ",
			what,xs);
		fflush(stdout);

		BC y = func(x,scale);
		ys = y.as_string();
		printf("%s; ",ys);
		fflush(stdout);

		std::stringstream ss;

		ss << "echo 'scale=" << scale << "; " << bcfun << "(" << xs << ")' | bc -l 2>&1";
		const std::string cmd = ss.str();
		FILE *bc = popen(cmd.c_str(),"r");
		char buf[1024];

		if ( fgets(buf,sizeof buf,bc) ) {
			cp = strchr(buf,'\n');
			if ( cp )
				*cp = 0;

			BC check(buf);

			if ( y != check ) {
				fputs("failed!\n",stdout);

				printf( "cmd: %s\n"
					" y = %s\n"
					"bc = %s%s\n"
					" x = %s\n",
					cmd.c_str(),
					ys,
					*buf == '.' ? "0" : "",
					buf,xs);
				free(xs);
				free(ys);
				return false;
			}
		} else	{
			assert(0);
		}
		pclose(bc);
		fputs("ok!\n",stdout);
		fflush(stdout);

		free(xs);
		free(ys);
		ys = xs = 0;

		x += by;
	}

	return true;
}
#endif

int
main(int argc,char **argv) {
#if 0
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

	{
		BC y = BC::ln(BC("3.5"),24);

		y.dump("ln(3.5) = ");
		y = BC::ln(BC("-3.5"),24);
		y.dump("ln(-3.5) = ");
	}
#endif

#if 0
	test_fun(0,+3,"0.03",BC::arctan,33,"arctan","a");
	test_fun(-6,+6,"0.031",BC::sin,33,"sin","s");
	test_fun(-6,+6,"0.01",BC::cos,33,"cos","c");
	test_fun(0,+5,"0.01",BC::sqrt,33,"sqrt","sqrt");
	test_fun(-5,+5,"0.03",BC::e,33,"e","e");
	test_fun(0,+5,"0.01",BC::ln,33,"ln","l");
	test_fun(-3,-1,"0.01",BC::ln,33,"ln","l");

	char *pi = BC::pi(50).as_string();
	printf("pi(50) = %s\n",pi);
	free(pi);
#endif
#if 0
	{
		BC x(1), z;

		z = BC::arcsin(x,28);
		printf("z=%s for arcsin(1)\n",z.as_string());
	}
	{
		BC x(".704"), y, z;

		y = BC::sin(x,28);
		z = BC::arcsin(y,28);
		printf("sin: x=%s, y=%s, z=%s\n",x.as_string(),y.as_string(),z.as_string());
	}
	{
		BC x(0), z;
		
		z = BC::arccos(0,28);
		printf("z=%s for arccos(0)\n",z.as_string());
	}
	{
		BC x(".704"), y, z;

		y = BC::cos(x,28);
		z = BC::arccos(y,28);
		printf("cos: x=%s, y=%s, z=%s\n",x.as_string(),y.as_string(),z.as_string());
	}

	{
		BC rad(BC::pi(32)/BC(4),32), deg, rad2;

		deg = BC::degrees(rad,32);
		rad2 = BC::radians(deg,32);

		printf("r=%s, d=%s, r2=%s\n",
			rad.as_string(),
			deg.as_string(),
			rad2.as_string());
	}
	{
		BC x(".6"), t, u;

		t = BC::tan(x,40);
		u = BC::arctan(t,40);
		printf("tan(%s,40) = %s\narctan() = %s\n",x.as_string(),t.as_string(),u.as_string());
	}

	{
		BC ax("1.65",40);
		BC acot(BC::arccot(ax,40));
		BC asec(BC::arcsec(ax,40));
		BC acsc(BC::arccsc(ax,40));

		printf("x=%s:\nacot=%s\nasec=%s\nacsc=%s\n",
			ax.as_string(),
			acot.as_string(),
			asec.as_string(),
			acsc.as_string());
	}
#endif

#if 0
	{
		BF a("100.1",12), b("99.9",12);
		char *sa, *sb;

		sa = a.as_string();
		sb = b.as_string();
		printf("a0=%s, b0=%s\n",sa,sb);
		free(sa);
		free(sb);

		a.shift(1);
		b.shift(-1);
		sa = a.as_string();
		sb = b.as_string();
		printf("a1=%s, b1=%s\n",sa,sb);
		free(sa);
		free(sb);
	}
#endif
	{
		BF x("123.4",6), y("1.5",6);
		char *sx, *sy;

		sx = x.as_string();
		sy = y.as_string();

		printf("x=%s\n",sx);
		printf("y=%s\n",sy);
		free(sx);
		free(sy);

		BF r(0,6);
		char *sr;

		r = x + y;
		sr = r.as_string();
		printf("x + y = r = %s\n",sr);
		free(sr);

		r = x - y;
		sr = r.as_string();
		printf("x - y = r = %s\n",sr);
		free(sr);

		y.assign(".0000653");
		sx = x.as_string();
		sy = y.as_string();
		printf("x=%s\n",sx);
		printf("y=%s\n",sy);
		free(sx);
		free(sy);

		r = x + y;
		sr = r.as_string();
		printf("x + y = r = %s\n",sr);
		free(sr);

		const char *vp;
		y.assign(vp="5.03E2");
		sy = y.as_string();
		printf("y=%s (%s)\n",sy,vp);
		free(sy);

		y.assign(vp="5E2");
		sy = y.as_string();
		printf("y=%s (%s)\n",sy,vp);
		free(sy);

		y.assign(vp="5E-1");
		sy = y.as_string();
		printf("y=%s (%s)\n",sy,vp);
		free(sy);

		x.assign("10.05");
		y.assign("6.78E-2");
		sx = x.as_string();
		sy = y.as_string();
		printf("x=%s\n",sx);
		printf("y=%s\n",sy);
		free(sx);
		free(sy);

		r = x * y;
		sr = r.as_string();
		printf("x * y = r = %s\n",sr);
		free(sr);

		x.assign("10.05");
		y.assign("6.78E-2");
		sx = x.as_string();
		sy = y.as_string();
		printf("x=%s\n",sx);
		printf("y=%s\n",sy);
		free(sx);
		free(sy);

		r = x / y;
		sr = r.as_string();
		printf("x / y = r = %s\n",sr);
		free(sr);

		r.negate();
		sr = r.as_string();
		printf("r.negate() = %s\n",sr);
		free(sr);

		r = x;
		sr = r.as_string();
		printf("r := x = %s\n",sr);
		free(sr);
	}

	if ( bc_valgrind )
		bc_fini_numbers();		// Not required, except for valgrind testing

	return 0;
}

// End testmain.cpp
