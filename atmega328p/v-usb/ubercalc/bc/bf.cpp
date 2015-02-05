
///////////////////////////////////////////////////////////////////////
// bf.cpp -- Implementation of BigFloat on top of bc number
// Date: Tue Feb  3 22:48:23 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <assert.h>

#include "bf.hpp"

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

	int scale;
	const char *cp;

	for ( cp = val; *cp != '.'; ++cp )
		;
	if ( *cp == '.' )
		scale = strlen(cp+1);
	else	scale = 0;
	bc_str2num(&num,val,scale);
	exponent = 0;
	mantissa = mant;
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
			if ( lz > 0 ) {
				exponent -= lz + 1;
				bc_shift_digits(&num,lz+1);
			}
		}
	}

	bc_num a = bc_copy_num(num);
	bc_divide(a,_one_,&num,mantissa);
	bc_free_num(&a);

	return *this;
}

char *
BF::as_string() {

	normalize();

	bc_num temp;
	bc_init_num(&temp);
	bc_int2num(&temp,exponent);

	char *m = bc_num2str(num);
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

BF
BF::operator+(const BF& rvalue) const {
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
	bc_add(a.num,b.num,&r,mantissa*2);
	BF R(r,mantissa);
	R.exponent = e;
	return R.normalize();
}

BF
BF::operator-(const BF& rvalue) const {
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
	bc_sub(a.num,b.num,&r,mantissa*2);
	BF R(r,mantissa);
	R.exponent = e;
	return R.normalize();
}

// End bf.cpp
