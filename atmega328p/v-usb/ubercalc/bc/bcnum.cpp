///////////////////////////////////////////////////////////////////////
// bcnum.cpp -- BC_Num Class Implementation
// Date: Thu Jan 29 21:37:05 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include "bcnum.hpp"

static bool iflag = false;		// True after initialization

BC_Num::BC_Num() {
	if ( !iflag ) {
		bc_init_numbers();
		iflag = true;
	}
	bc_init_num(&num);
}

BC_Num::~BC_Num() {
	bc_free_num(&num);
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
