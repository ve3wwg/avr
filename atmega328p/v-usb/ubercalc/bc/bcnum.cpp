///////////////////////////////////////////////////////////////////////
// bcnum.cpp -- BC_Num Class Implementation
// Date: Thu Jan 29 21:37:05 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include "bcnum.hpp"

BC_Num::BC_Num() {
	if ( !bc_inited )
		bc_init_numbers();
	bc_init_num(&num);
}

BC_Num::BC_Num(const char *val) {
	bc_init_num(&num);

	assign(val);
}

BC_Num::BC_Num(int val) {
	if ( !bc_inited )
		bc_init_numbers();

	bc_init_num(&num);
	bc_int2num(&num,val);
}

BC_Num::~BC_Num() {
	bc_free_num(&num);
}

BC_Num&
BC_Num::assign(const char *val) {
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
BC_Num::common_scale(const BC_Num& rvalue) const {
	return num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;
}

BC_Num
BC_Num::operator+(const BC_Num& rvalue) const {
	bc_num result;

	bc_init_num(&result);
	bc_add(num,rvalue.num,&result,common_scale(rvalue));
	return BC_Num(result);
}

BC_Num
BC_Num::operator-() const {
	bc_num result = bc_copy_num(_zero_);

	bc_sub(result,num,&result,num->n_scale);
	return BC_Num(result);
}

BC_Num
BC_Num::operator-(const BC_Num& rvalue) const {
	bc_num result;

	bc_init_num(&result);
	bc_sub(num,rvalue.num,&result,common_scale(rvalue));
	return BC_Num(result);
}

BC_Num
BC_Num::operator*(const BC_Num& rvalue) const {
	bc_num result;

	bc_init_num(&result);
	bc_multiply(num,rvalue.num,&result,num->n_scale+rvalue.num->n_scale);
	return BC_Num(result);
}

BC_Num
BC_Num::operator/(const BC_Num& rvalue) const {
	bc_num result;
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_init_num(&result);
	bc_divide(num,rvalue.num,&result,scale);
	return BC_Num(result);
}

BC_Num
BC_Num::div(const BC_Num& rvalue,int scale) const {
	bc_num result;

	bc_init_num(&result);
	bc_divide(num,rvalue.num,&result,scale);
	return BC_Num(result);
}

BC_Num
BC_Num::operator%(const BC_Num& rvalue) const {
	bc_num result;
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_init_num(&result);
	bc_modulo(num,rvalue.num,&result,scale);
	return BC_Num(result);
}

BC_Num
BC_Num::divmod(const BC_Num& divisor,BC_Num& mod,int scale) const {
	bc_num q;

	bc_init_num(&q);
	bc_divmod(num,divisor.num,&q,&mod.num,scale);
	return BC_Num(q);
}

BC_Num
BC_Num::operator^(const BC_Num& rvalue) const {
	bc_num result;
	long s2 = bc_num2long(rvalue.num);
	int scale = num->n_scale * s2;

	bc_init_num(&result);
	bc_raise(num,rvalue.num,&result,scale);
	return BC_Num(result);
}

BC_Num
BC_Num::raisemod(const BC_Num& exp,const BC_Num& mod,int scale) const {
	bc_num r;

	bc_init_num(&r);
	bc_raisemod(num,exp.num,mod.num,&r,scale);
	return BC_Num(r);
}

bool
BC_Num::operator!() const {
	return !!bc_is_zero(num);
}

bool
BC_Num::is_near_zero(int scale) const {
	return !!bc_is_near_zero(num,scale);
}

bool
BC_Num::operator<(const BC_Num& rvalue) const {
	return bc_compare(num,rvalue.num) < 0;
}

bool
BC_Num::operator<=(const BC_Num& rvalue) const {
	return bc_compare(num,rvalue.num) <= 0;
}

bool
BC_Num::operator==(const BC_Num& rvalue) const {
	return bc_compare(num,rvalue.num) == 0;
}

bool
BC_Num::operator!=(const BC_Num& rvalue) const {
	return bc_compare(num,rvalue.num) != 0;
}

bool
BC_Num::operator>=(const BC_Num& rvalue) const {
	return bc_compare(num,rvalue.num) >= 0;
}

bool
BC_Num::operator>(const BC_Num& rvalue) const {
	return bc_compare(num,rvalue.num) > 0;
}

bool
BC_Num::is_negative() const {
	return !!bc_is_neg(num);
}

BC_Num
BC_Num::negate() const {
	bc_num r = bc_copy_num(_zero_);

	bc_sub(r,num,&r,num->n_scale);
	return BC_Num(r);
}

BC_Num&
BC_Num::operator++() {
	bc_add(_one_,num,&num,num->n_scale);
	return *this;
}

BC_Num&
BC_Num::operator--() {
	bc_sub(num,_one_,&num,num->n_scale);
	return *this;
}

BC_Num&
BC_Num::operator+=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_add(num,r,&num,common_scale(rvalue));
	bc_free_num(&r);
	return *this;
}

BC_Num&
BC_Num::operator+=(const BC_Num& rvalue) {
	bc_add(num,rvalue.num,&num,common_scale(rvalue));
	return *this;
}

BC_Num&
BC_Num::operator-=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_sub(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC_Num&
BC_Num::operator-=(const BC_Num& rvalue) {
	bc_sub(num,rvalue.num,&num,common_scale(rvalue));
	return *this;
}

BC_Num&
BC_Num::operator*=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_multiply(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC_Num&
BC_Num::operator*=(const BC_Num& rvalue) {
	int scale = num->n_scale + rvalue.num->n_scale;
	bc_multiply(num,rvalue.num,&num,scale);
	return *this;
}

BC_Num&
BC_Num::operator/=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_divide(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC_Num&
BC_Num::operator/=(const BC_Num& rvalue) {
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_divide(num,rvalue.num,&num,scale);
	return *this;
}

BC_Num&
BC_Num::operator%=(int rvalue) {
	bc_num r = bc_copy_num(_zero_);
	bc_int2num(&r,rvalue);
	bc_modulo(num,r,&num,num->n_scale);
	bc_free_num(&r);
	return *this;
}

BC_Num&
BC_Num::operator%=(const BC_Num& rvalue) {
	int scale = num->n_scale > rvalue.num->n_scale ? num->n_scale : rvalue.num->n_scale;

	bc_modulo(num,rvalue.num,&num,scale);
	return *this;
}

static void
out_dig(int c) {
	putchar(c);
}

void
BC_Num::dump(const char *prefix) const {
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

BC_Num
BC_Num::atan(const BC_Num& x,int scale) {
	BC_Num z(scale), a, Pt2(".2"), f, v, n, e, i, s, m(_one_), X(x);

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
		m = BC_Num::zero() - BC_Num::one();	// m = -1;
		X = BC_Num::zero() - x;			// x = -x;
	}

  	// Special case and for fast answers
	if ( X == BC_Num::one() ) {
		if ( scale <= 25 )
			return BC_Num(".7853981633974483096156608") / m;
		if ( scale <= 40 )
			return BC_Num(".7853981633974483096156608458198757210492") / m;
		if ( scale <= 60 )
			return BC_Num(".785398163397448309615660845819875721049292349843776455243736") / m;
	}

	if ( X == Pt2 ) {
		if ( scale <= 25 )
			return BC_Num(".1973955598498807583700497") / m;
		if ( scale <= 40 )
			return BC_Num(".1973955598498807583700497651947902934475") / m;
		if ( scale <= 60 )
			return BC_Num(".197395559849880758370049765194790293447585103787852101517688") / m;
	}

	// Note: a and f are known to be zero due to being auto vars.
	// Calculate atan of a known number.

	if ( X > Pt2 ) {
		z += BC_Num(5);
		a = Pt2;
	}
   
	// Precondition x.
	scale = z.as_long() + 3;

	while ( X > Pt2 ) {
		++f;
		X = (X - Pt2) / (BC_Num::one() + X * Pt2);
	}

	// Initialize the series.
	v = n = X;
	s = (-X) * X;

	// Calculate the series.
	for ( i = 3; 1; i += BC_Num::two() ) {
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

BC_Num
BC_Num::sin(const BC_Num& x,int scale) {
	BC_Num e, i, m, n, s, v, z(scale), sc, X(x), Four(4);

	sc = BC_Num("1.1") * z + BC_Num::two();	// scale = 1.1 * z + 2
	v = atan(BC_Num::one(),scale);

	if ( X.is_negative() ) {
		m = BC_Num::one();	// m = 1;
		X = -X;			// x = -x;
	}

	sc = 0;
	n = (X / v + 2 ) / Four;
	X = X - Four * n * v;

	if ( (n % BC_Num::two()).as_long() )
		X = -X;			// x = -x

	// Do the loop.
	sc = z + 2;
	v = e = x;
	s = (-X) * X;

	for ( i=3; 1; i += BC_Num::two() ) {
		e *= s / ( i * (i-BC_Num::one()) );
		if ( !e ) {
			sc = z;
			if ( !!m )
				return -v / BC_Num::one();
			return v / BC_Num::one();
		}
		v += e;
	}
}

// End bcnum.cpp
