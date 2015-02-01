///////////////////////////////////////////////////////////////////////
// bcnum.cpp -- BC Class Implementation
// Date: Thu Jan 29 21:37:05 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include "bcnum.hpp"

BC::BC() {
	if ( !bc_inited )
		bc_init_numbers();
	bc_init_num(&num);
}

BC::BC(const char *val) {
	bc_init_num(&num);

	assign(val);
}

BC::BC(int val) {

	if ( !bc_inited )
		bc_init_numbers();

	if ( val == 0 )
		num = bc_copy_num(_zero_);
	else if ( val == 1 )
		num = bc_copy_num(_one_);
	else if ( val == 1 )
		num = bc_copy_num(_two_);
	else	{
		bc_init_num(&num);
		bc_int2num(&num,val);
	}
}

BC::~BC() {
	bc_free_num(&num);
}

BC&
BC::assign(const char *val) {
	const char *cp = val;
	unsigned scale = 0;

	for ( ; *cp && *cp != '.'; ++cp )
		;
	if ( *cp == '.' )
		for ( ++cp; *cp++; )
			++scale;

	if ( !bc_inited )
		bc_init_numbers();

	bc_str2num(&num,val,scale);
	return *this;
}

int
BC::common_scale(const BC& rvalue) const {
	return num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;
}

BC
BC::operator+(const BC& rvalue) const {
	bc_num result;

	bc_init_num(&result);
	bc_add(num,rvalue.num,&result,common_scale(rvalue));
	return BC(result);
}

BC
BC::operator-() const {
	bc_num result = bc_copy_num(_zero_);

	bc_sub(result,num,&result,num->n_scale);
	return BC(result);
}

BC
BC::operator-(const BC& rvalue) const {
	bc_num result;

	bc_init_num(&result);
	bc_sub(num,rvalue.num,&result,common_scale(rvalue));
	return BC(result);
}

BC
BC::operator*(const BC& rvalue) const {
	bc_num result;

	bc_init_num(&result);
	bc_multiply(num,rvalue.num,&result,num->n_scale+rvalue.num->n_scale);
	return BC(result);
}

BC
BC::operator/(const BC& rvalue) const {
	bc_num result;
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_init_num(&result);
	bc_divide(num,rvalue.num,&result,scale);
	return BC(result);
}

BC
BC::div(const BC& rvalue,int scale) const {
	bc_num result;

	bc_init_num(&result);
	bc_divide(num,rvalue.num,&result,scale);
	return BC(result);
}

BC
BC::operator%(const BC& rvalue) const {
	bc_num result;
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_init_num(&result);
	bc_modulo(num,rvalue.num,&result,scale);
	return BC(result);
}

BC
BC::divmod(const BC& divisor,BC& mod,int scale) const {
	bc_num q;

	bc_init_num(&q);
	bc_divmod(num,divisor.num,&q,&mod.num,scale);
	return BC(q);
}

BC
BC::operator^(const BC& rvalue) const {
	bc_num result;
	long s2 = bc_num2long(rvalue.num);
	int scale = num->n_scale * s2;

	bc_init_num(&result);
	bc_raise(num,rvalue.num,&result,scale);
	return BC(result);
}

BC
BC::raisemod(const BC& exp,const BC& mod,int scale) const {
	bc_num r;

	bc_init_num(&r);
	bc_raisemod(num,exp.num,mod.num,&r,scale);
	return BC(r);
}

bool
BC::operator!() const {
	return !!bc_is_zero(num);
}

bool
BC::is_near_zero(int scale) const {
	return !!bc_is_near_zero(num,scale);
}

bool
BC::operator<(const BC& rvalue) const {
	return bc_compare(num,rvalue.num) < 0;
}

bool
BC::operator<=(const BC& rvalue) const {
	return bc_compare(num,rvalue.num) <= 0;
}

bool
BC::operator==(const BC& rvalue) const {
	return bc_compare(num,rvalue.num) == 0;
}

bool
BC::operator!=(const BC& rvalue) const {
	return bc_compare(num,rvalue.num) != 0;
}

bool
BC::operator>=(const BC& rvalue) const {
	return bc_compare(num,rvalue.num) >= 0;
}

bool
BC::operator>(const BC& rvalue) const {
	return bc_compare(num,rvalue.num) > 0;
}

bool
BC::is_negative() const {
	return !!bc_is_neg(num);
}

BC
BC::negate() const {
	bc_num r = bc_copy_num(_zero_);

	bc_sub(r,num,&r,num->n_scale);
	return BC(r);
}

BC&
BC::operator++() {
	bc_add(_one_,num,&num,num->n_scale);
	return *this;
}

BC&
BC::operator--() {
	bc_sub(num,_one_,&num,num->n_scale);
	return *this;
}

BC&
BC::operator+=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_add(num,r,&num,common_scale(rvalue));
	bc_free_num(&r);
	return *this;
}

BC&
BC::operator+=(const BC& rvalue) {
	bc_add(num,rvalue.num,&num,common_scale(rvalue));
	return *this;
}

BC&
BC::operator-=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_sub(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC&
BC::operator-=(const BC& rvalue) {
	bc_sub(num,rvalue.num,&num,common_scale(rvalue));
	return *this;
}

BC&
BC::operator*=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_multiply(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC&
BC::operator*=(const BC& rvalue) {
	int scale = num->n_scale + rvalue.num->n_scale;
	bc_multiply(num,rvalue.num,&num,scale);
	return *this;
}

BC&
BC::operator/=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_divide(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC&
BC::operator/=(const BC& rvalue) {
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_divide(num,rvalue.num,&num,scale);
	return *this;
}

BC&
BC::operator%=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_modulo(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC&
BC::operator%=(const BC& rvalue) {
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_modulo(num,rvalue.num,&num,scale);
	return *this;
}

static void
out_dig(int c) {
	putchar(c);
}

void
BC::dump(const char *prefix) const {
	if ( prefix )
		fputs(prefix,stdout);
	bc_out_num(num,10,out_dig,0);	
	putchar('\n');
	fflush(stdout);
}

//////////////////////////////////////////////////////////////////////
// Math Functions
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
// Arctan: Using the formula:
//   atan(x) = atan(c) + atan((x-c)/(1+xc)) for a small c (.2 here)
// For under .2, use the series:
//   atan(x) = x - x^3/3 + x^5/5 - x^7/7 + ...   */
//////////////////////////////////////////////////////////////////////

BC
BC::atan(const BC& x,int scale) {
	BC z(scale), a, Pt2(".2"), f, v, n, e, i, s, m(1), X(x);

	// a is the value of a(.2) if it is needed.
	// f is the value to multiply by a in the return.
	// e is the value of the current term in the series.
	// v is the accumulated value of the series.
	// m is 1 or -1 depending on x (-x -> -1).  results are divided by m.
	// i is the denominator value for series element.
	// n is the numerator value for the series element.
	// s is -x*x.
	// z is the saved user's scale.

  	// Negative x?
	if ( X.is_negative() ) {
		m = BC(-1);			// m = -1;
		X = -X;				// x = -x;
	}

  	// Special case and for fast answers
	if ( X == BC(1) ) {
#if 0
		if ( scale <= 25 )
			return BC(".7853981633974483096156608") / m;
		if ( scale <= 40 )
			return BC(".7853981633974483096156608458198757210492") / m;
		if ( scale <= 60 )
#endif
			return BC(".785398163397448309615660845819875721049292349843776455243736") / m;
	}

	if ( X == Pt2 ) {
#if 0
		if ( scale <= 25 )
			return BC(".1973955598498807583700497") / m;
		if ( scale <= 40 )
			return BC(".1973955598498807583700497651947902934475") / m;
		if ( scale <= 60 )
#endif
			return BC(".197395559849880758370049765194790293447585103787852101517688") / m;
	}

	// Note: a and f are known to be zero due to being auto vars.
	// Calculate atan of a known number.

	if ( X > Pt2 ) {
		z += BC(5);
		a = Pt2;
	}
   
	// Precondition x.
	scale = z.as_long() + 3;

	while ( X > Pt2 ) {
		++f;
		X = (X - Pt2) / (BC(1) + X * Pt2);
	}

	// Initialize the series.
	v = n = X;
	s = (-X) * X;

	// Calculate the series.
	for ( i = 3; 1; i += BC(2) ) {
		e = (n *= s) / i;
		if ( !e ) {
			scale = z.as_long();
			return (f*a+v) / m;
		}
		v += e;
	}
}

//////////////////////////////////////////////////////////////////////
// Sin(x)  uses the standard series:
// sin(x) = x - x^3/3! + x^5/5! - x^7/7! ... */
//////////////////////////////////////////////////////////////////////

BC
BC::sin(const BC& x,int scale) {
	BC e, i, m, n, s, v, z(scale), sc, X(x), Four(4);

	sc = BC("1.1") * z + BC::two();	// scale = 1.1 * z + 2
	v = atan(BC::one(),scale);

	if ( X.is_negative() ) {
		m = BC::one();	// m = 1;
		X = -X;			// x = -x;
	}

	sc = 0;
	n = (X / v + 2 ) / Four;
	X = X - Four * n * v;

	if ( (n % BC::two()).as_long() )
		X = -X;			// x = -x

	// Do the loop.
	sc = z + 2;
	v = e = x;
	s = (-X) * X;

	for ( i=3; 1; i += BC::two() ) {
		e *= s / ( i * (i-BC::one()) );
		if ( !e ) {
			sc = z;
			if ( !!m )
				return -v / BC::one();
			return v / BC::one();
		}
		v += e;
	}
}

// End bcnum.cpp
