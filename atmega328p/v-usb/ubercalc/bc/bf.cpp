
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
			unsigned dig = num->n_len - 1;
			bc_num ten, power, mul;
	
			bc_init_num(&mul);
			bc_init_num(&ten);
			bc_init_num(&power);
			bc_int2num(&ten,10);
			bc_int2num(&power,num->n_len-1);
			bc_raise(ten,power,&mul,0);
			ten = bc_copy_num(num);
			bc_divide(ten,mul,&num,mantissa-1);
			exponent += int(dig);
			bc_free_num(&mul);
			bc_free_num(&ten);
			bc_free_num(&power);
		} else if ( ( num->n_len == 1 && !*num->n_value ) || num->n_len == 0 ) {
			unsigned lz = bc_leadingfz(num);

			if ( lz > 0 ) {
				bc_num ten, power, mul;
				
				bc_init_num(&mul);
				bc_init_num(&ten);
				bc_init_num(&power);
				bc_int2num(&ten,10);
				bc_int2num(&power,int(lz+1));
				bc_raise(ten,power,&mul,0);
				bc_multiply(num,mul,&power,mantissa-1);
				bc_int2num(&ten,1);
				bc_divide(power,ten,&num,mantissa-1);
				exponent -= int(lz+1);
				bc_free_num(&mul);
				bc_free_num(&ten);
				bc_free_num(&power);
			}
		}
	}

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
	if ( exponent > 0 )
		*m++ = '+';
	strcpy(m,e);
	
	free(e);
	return r;
}

// End bf.cpp
