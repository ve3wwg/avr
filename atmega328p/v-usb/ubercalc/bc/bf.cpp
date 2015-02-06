
///////////////////////////////////////////////////////////////////////
// bf.cpp -- Implementation of Bcursed!igFloat on top of bc number
// Date: Tue Feb  3 22:48:23 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <assert.h>

#include "bf.hpp"
#include "bc.hpp"

#define IABS(a) 	((a)>=0?(a):(-(a)))
#define MANT(a,b)	(((a).mantissa) >= ((b).mantissa) ? ((a).mantissa) : ((b).mantissa) )

BF::BF(unsigned mant) {

	if ( !bc_inited )
		bc_init_numbers();

	bc_init_num(&num);
	exponent = 0;
	mantissa = mant;
}

BF::BF(int intval,unsigned mant) {

	if ( !bc_inited )
		bc_init_numbers();

	bc_init_num(&num);
	bc_int2num(&num,intval);
	exponent = 0;
	mantissa = mant;
}

BF::BF(bc_num num,unsigned mant) {

	if ( !bc_inited )
		bc_init_numbers();

	this->num = num;
	exponent = 0;
	mantissa = mant;
}

BF::BF(const char *val,unsigned mant) {

	if ( !bc_inited )
		bc_init_numbers();

	exponent = 0;
	mantissa = mant;

	bc_init_num(&num);
	this->assign(val);
}

BF::BF(const BF& other) {

	if ( !bc_inited )
		bc_init_numbers();

	num = bc_copy_num(other.num);
	exponent = other.exponent;
	mantissa = other.mantissa;
}

BF&
BF::normalize() {

	if ( !bc_is_zero(num) ) {
		if ( num->n_len > 1 ) {
			exponent += num->n_len-1;
			bc_shift_digits(&num,-(num->n_len-1));
		} else if ( ( num->n_len == 1 && !*num->n_value ) || num->n_len == 0 ) {
			unsigned lz = bc_leadingfz(num);
			exponent -= lz + 1;
			bc_shift_digits(&num,lz+1);
		}
	}

	bc_num a = bc_copy_num(num);
	bc_divide(a,_one_,&num,mantissa);
	bc_free_num(&a);

	return *this;
}

BF&
BF::assign(const char *val) {
	int scale;
	const char *cp;
	const char *ee = 0;

	for ( cp = val; *cp && *cp != '.'; ++cp )
		if ( *cp == 'e' || *cp == 'E' )
			break;		// Break at start of exponent

	if ( *cp == 'e' || *cp == 'E' ) {
		ee = cp;		// Start of exponent
		scale = 0;		// with no decimal point in mantissa
	} else if ( *cp == '.' ) {
		scale = strlen(cp+1);
		for ( ee=cp+1; *ee && *ee != 'e' && *ee != 'E'; ++ee ) 
			;		// Got decimal point, but scan for exponent (if any)
		if ( *ee != 'e' && *ee != 'E' )
			ee = 0;		// No exponent
	} else	
		scale = 0;		// No decimal point, no exponent

	bc_str2num(&num,val,scale,1);	// Stops on 'E' (when present)

	if ( ee && *++ee != 0 ) {	// Extract exponent?
		bc_num exp;

		bc_init_num(&exp);
		bc_str2num(&exp,ee,0);
		exponent = bc_num2long(exp);
		bc_free_num(&exp);
	} else	{
		exponent = 0;
	}

	return *this;
}

char *
BF::as_string() const {
	BF t(*this);

	t.normalize();

	bc_num temp;
	bc_init_num(&temp);
	bc_int2num(&temp,t.exponent);

	char *m = bc_num2str(t.num);
	char *e = bc_num2str(temp);	

	int lm = strlen(m);
	int le = strlen(e);
	int tlen = lm + 2 + le + 1;

	char *r = (char *)bc_malloc(tlen);
	strcpy(r,m);
	free(m);

	m = r+lm;
	*m++ = 'E';
	strcpy(m,e);
	
	free(e);
	return r;
}

long
BF::as_long() const {

	if ( exponent == 0 )
		return bc_num2long(num);

	if ( exponent > 0 ) {
		bc_num temp = bc_copy_num(num);
		bc_shift_digits(&temp,exponent);
		long r = bc_num2long(temp);
		bc_free_num(&temp);
		return r;
	}

	return 0L;
}

//////////////////////////////////////////////////////////////////////
// INTERNAL: Add/Sub
//////////////////////////////////////////////////////////////////////

BF
BF::addsub(const BF& rvalue,int sub) const {
	int ediff = IABS(this->exponent - rvalue.exponent);

	if ( ediff > mantissa ) {
		// Too large a difference for sum/difference to matter
		if ( this->exponent > rvalue.exponent )
			return BF(*this);
		else	return BF(rvalue);
	}

	int e;
	BF a(*this);
	BF b(rvalue);

	a.normalize();
	b.normalize();

	if ( this->exponent > rvalue.exponent ) {
		e = this->exponent;
		bc_shift_digits(&b.num,rvalue.exponent-this->exponent);
	} else if ( this->exponent < rvalue.exponent ) {
		e = rvalue.exponent;
		bc_shift_digits(&a.num,this->exponent-rvalue.exponent);
	} else	e = this->exponent;

	bc_num r;
	bc_init_num(&r);
	if ( !sub )
		bc_add(a.num,b.num,&r,mantissa*2);
	else	bc_sub(a.num,b.num,&r,mantissa*2);

	BF R(r,mantissa);
	R.exponent = e;
	return R.normalize();
}

BF
BF::operator+(const BF& rvalue) const {
	return addsub(rvalue,0);
}

BF
BF::operator-(const BF& rvalue) const {
	return addsub(rvalue,1);
}

BF
BF::operator*(const BF& rvalue) const {
	bc_num r;

	bc_init_num(&r);
	bc_multiply(num,rvalue.num,&r,num->n_scale+rvalue.num->n_scale);
	BF R(r,mantissa);		// This steals r
	R.exponent = exponent + rvalue.exponent;
	return R.normalize();
}

BF
BF::operator/(const BF& rvalue) const {
	bc_num r;

	bc_init_num(&r);
	bc_divide(num,rvalue.num,&r,num->n_scale+rvalue.num->n_scale);
	BF R(r,mantissa);		// This steals r
	R.exponent = exponent - rvalue.exponent;
	return R.normalize();
}

BF&
BF::negate() {
	num->n_sign ^= 1;
	return *this;
}

BF&
BF::operator=(const BF& rvalue) {
	mantissa = rvalue.mantissa;
	exponent = rvalue.exponent;
	num = bc_copy_num(rvalue.num);
	return *this;
}

bool
BF::operator!() const {
	return bc_is_zero(num);
}

BF
BF::operator-() const {
	BF r(*this);

	r.num->n_sign ^= 1;
	return r;
}

int
BF::compare(const BF& rvalue) const {

	if ( !*this && !rvalue )
		return 0;			// These equal (exponents are meaningless here)

	if ( exponent < rvalue.exponent )
		return -1;
	else if ( exponent > rvalue.exponent )
		return +1;

	bc_num r;
	bc_init_num(&r);
	bc_sub(num,rvalue.num,&r,num->n_scale>=rvalue.num->n_scale?num->n_scale:rvalue.num->n_scale);

	int rc;
	if ( bc_is_zero(r) ) 
		rc = 0;
	else if ( bc_is_neg(r) )
		rc = -1;
	else	rc = +1;
	bc_free_num(&r);

	return rc;
}

bool
BF::operator<(const BF& rvalue) const {
	return compare(rvalue) < 0;
}

bool
BF::operator<=(const BF& rvalue) const {
	return compare(rvalue) <= 0;
}

bool
BF::operator==(const BF& rvalue) const {
	return compare(rvalue) == 0;
}

bool
BF::operator!=(const BF& rvalue) const {
	return compare(rvalue) != 0;
}

bool
BF::operator>=(const BF& rvalue) const {
	return compare(rvalue) >= 0;
}

bool
BF::operator>(const BF& rvalue) const {
	return compare(rvalue) > 0;
}

BF&
BF::operator++() {
	*this = BF(*this) + BF(bc_copy_num(_one_),mantissa);
	return *this;
}

BF&
BF::operator--() {
	*this = BF(*this) - BF(bc_copy_num(_one_),mantissa);
	return *this;
}

BF
BF::operator++(int) {
	BF R(*this);
	*this = BF(*this) + BF(bc_copy_num(_one_),mantissa);
	return R;
}

BF
BF::operator--(int) {
	BF R(*this);
	*this = BF(*this) - BF(bc_copy_num(_one_),mantissa);
	return R;
}

BF&
BF::operator+=(const BF& rvalue) {
	*this = *this + rvalue;
	return *this;
}

BF&
BF::operator-=(const BF& rvalue) {
	*this = *this - rvalue;
	return *this;
}

BF&
BF::operator*=(const BF& rvalue) {
	*this = *this * rvalue;
	return *this;
}

BF&
BF::operator/=(const BF& rvalue) {
	*this = *this / rvalue;
	return *this;
}

//////////////////////////////////////////////////////////////////////
// int operations
//////////////////////////////////////////////////////////////////////

BF&
BF::operator=(int rvalue) {
	exponent = 0;
	bc_int2num(&num,rvalue);
	return *this;
}

BF
BF::operator+(int rvalue) const {
	return *this + BF(rvalue,mantissa);
}

BF
BF::operator-(int rvalue) const {
	return *this - BF(rvalue,mantissa);
}

BF
BF::operator*(int rvalue) const {
	return *this * BF(rvalue,mantissa);
}

BF
BF::operator/(int rvalue) const {
	return *this / BF(rvalue,mantissa);
}

BF&
BF::operator+=(int rvalue) {
	return *this += BF(rvalue,mantissa);
}

BF&
BF::operator-=(int rvalue) {
	return *this -= BF(rvalue,mantissa);
}

BF&
BF::operator*=(int rvalue) {
	return *this *= BF(rvalue,mantissa);
}

BF&
BF::operator/=(int rvalue) {
	return *this /= BF(rvalue,mantissa);
}

BF
BF::operator^(const BF& rvalue) const {
	// x^n= exp(n ln x)
#warning "Finish me.. power()"
	return BF(0,mantissa);
}

//////////////////////////////////////////////////////////////////////
// Static functions
//////////////////////////////////////////////////////////////////////

BF
BF::abs(const BF& x) {
	BF r(x);

	r.num->n_sign = 0;
	return r;
}

BF
BF::truncate(const BF& x) {
	BF r(x);
	if ( r.exponent > 0 )
		r.num->n_scale = r.exponent - 1;
	else	r.num->n_scale = 0;
	return r.normalize();
}

BF
BF::pi(int mantissa) {
	BC pi = BC::pi(mantissa+1);
	BF r(bc_copy_num(pi.num),mantissa);
	return r;
}

// INTERNAL:

BF
BF::pi_range(const BF& x) {
	BF temp(x);
	temp.normalize();

	if ( temp.exponent > 0 ) {
		BF pi(BF::pi(x.mantissa));
		BF m(x.mantissa);
		BF r(temp);
		m = BF::truncate(r / pi) * pi;
		return r -= m;
	} else	{
		return BF(x);
	}
}

#if 0
BF
BF::sin(const BF& x) {
	BF rx = BF::pi_range(x);
	return...
}
#endif

#if 0
sqrt(const
BF::BF& x) {
}

BF
BF::cos(const BF& x) {
}

BF
BF::tan(const BF& x) {
}
#endif

// End bf.cpp
