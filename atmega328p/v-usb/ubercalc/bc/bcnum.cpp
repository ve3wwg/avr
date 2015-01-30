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

BC_Num::~BC_Num() {
	bc_free_num(&num);
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
BC_Num::operator-(const BC_Num& rvalue) const {
	bc_num result;

	bc_init_num(&result);
	bc_sub(num,rvalue.num,&result,common_scale(rvalue));
	return BC_Num(result);
}

static void
out_dig(int c) {
	putchar(c);
}

void
BC_Num::dump() {
	bc_out_num(num,10,out_dig,0);	
	putchar('\n');
}

// End bcnum.cpp
