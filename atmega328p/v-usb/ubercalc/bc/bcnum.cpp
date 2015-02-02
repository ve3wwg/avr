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

BC::BC(const BC& other,int scale) {

	if ( !bc_inited )
		bc_init_numbers();
	bc_init_num(&num);
	bc_divide(other.num,_one_,&num,scale);
}

BC::BC(const char *val) {

	if ( !bc_inited )
		bc_init_numbers();
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
BC::rescale(int scale) {

	bc_num temp = bc_copy_num(num);
	bc_divide(temp,_one_,&num,scale);
	bc_free_num(&temp);
	return *this;
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

BC
BC::operator++(int) {
	bc_num temp = bc_copy_num(num);
	bc_add(_one_,num,&num,num->n_scale);
	return BC(temp);
}

BC&
BC::operator--() {
	bc_sub(num,_one_,&num,num->n_scale);
	return *this;
}

BC
BC::operator--(int) {
	bc_num temp = bc_copy_num(num);
	bc_sub(_one_,num,&num,num->n_scale);
	return BC(temp);
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

BC
BC::sqrt(const BC& x,int scale) {
	bc_num num = bc_copy_num(x.num);
	bc_sqrt(&num,scale);
	return BC(num);
}

static void
out_dig(int c,void *udata) {
	putchar(c);
}

void
BC::dump(const char *prefix) const {
	if ( prefix )
		fputs(prefix,stdout);
	bc_out_num(num,10,out_dig,0,0);	
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
	BC e, m, n, s, v, z(scale), sc, X(x), Four(4);

	sc = BC("1.1") * z + BC(2);	// scale = 1.1 * z + 2
	v = BC::atan(BC(1),sc.as_long());
	v.rescale(scale);

	if ( X.is_negative() ) {
		m = BC(1);		// m = 1;
		X = -X;			// x = -x;
	}

	sc = 0;
	n = (X / v + 2 ) / Four;
	n.rescale(Four.scale());

	X = X - Four * n * v;

	if ( !!(n % BC(2)) )
		X = -X;			// x = -x

	// Do the loop.
	v = e = X;
	s = (-X) * X;
	s.rescale(scale);

	int use_sc = z.as_long() + 2;

	for ( int i=3; 1; i += 2 ) {
		BC div(i * (i - 1));
		BC mul(s / div);
		mul.rescale(s.scale());

		// e *= s / ( i * (i-BC(1)) );
		e *= mul;
		e.rescale(use_sc);

		if ( !e ) {
			sc = z.as_long();
			v.rescale(sc.as_long());
			if ( !!m )
				return -v;
			return v;
		}
		v += e;
	}
}

BC
BC::cos(const BC& x,int scale) {
	BC v, sc(scale);

	sc *= BC("1.2");

	int use_scale = sc.as_long();
	v = sin(x + BC::atan(1,use_scale) * BC(2),use_scale);
	return v.rescale(scale);
}	

BC
BC::e(const BC& x,int scale) {
	int m = 0;
	BC a, d(1), e, f, n, v, z(scale), X(x);

	// a - holds x^y of x^y/y!
	// d - holds y!
	// e - is the value x^y/y!
	// v - is the sum of the e's
	// f - number of times x was divided by 2.
	// m - is 1 if x was minus.
	// i - iteration count.
	// n - the scale to compute the sum.
	// z - orignal scale.

	// Check the sign of x.
	if ( x.is_negative() ) {
		m = 1;
		X = -x;
	} 

	// Precondition x.
	n = z + 6 + BC(".44") * X;
	int use_scale = X.scale() + 1;

	while ( X > 1 ) {
		++f;
		X /= BC(2);
		X.rescale(use_scale);
		use_scale += 1;
	}

	// Initialize the variables.
	use_scale = n.as_long();

	v = X + 1;
	a = X;

	for ( int i=2; 1; ++i ) {
		e = (a *= X) / (d *= BC(i)).rescale(use_scale);
		e.rescale(use_scale);
		if ( e == 0 ) {
			if ( f > 0 )
				while ( f-- != 0 ) 
					v = v * v;

			use_scale = z.as_long();

			if ( m ) {
				v = BC(1) / v;
				v.rescale(use_scale);
			}
			v.rescale(use_scale);
			return v;
		}
		v += e;
	}
}

//////////////////////////////////////////////////////////////////////
// Natural log. Uses the fact that ln(x^2) = 2*ln(x)
// The series used is:
//   ln(x) = 2(a+a^3/3+a^5/5+...) where a=(x-1)/(x+1)
//////////////////////////////////////////////////////////////////////

BC
BC::ln(const BC& x,int scale) {

	// return something for the special case.
	if ( x.is_negative() )
		return ((BC(1) - (BC(10) ^ BC(scale))) / BC(1)).rescale(scale);

	BC e, f(2), m, n, v, X(x);
	int i = 0, z = scale;

	// Precondition x to make .5 < x < 2.0.
	scale = 6 + scale;

	while ( X >= 2 ) {	// for large numbers
		f *= BC(2);
		X = BC::sqrt(X,scale);
	}

	while ( X <= BC(".5") ) { // for small numbers
		f *= BC(2);
		X = BC::sqrt(X,scale);
	}
	
	// Set up the loop.
	v = n = ((X-1) / (X+1)).rescale(scale);
	m = n * n;
	
	// Sum the series.
	for ( i=3; 1; i += 2 ) {
		e = ((n *= m) / i).rescale(scale);

		if ( e == 0 ) {
			v = (f * v).rescale(z);
			return v;
		}
		v += e;
	}
}

// End bcnum.cpp
