//////////////////////////////////////////////////////////////////////
// bcnum.hpp -- BC_Num class
// Date: Thu Jan 29 21:32:54 2015   (C) Warren Gay ve3wwg
///////////////////////////////////////////////////////////////////////

#ifndef BCNUM_HPP
#define BCNUM_HPP

#include "number.hpp"


class BC_Num {
	bc_num		num;

protected:
	int common_scale(const BC_Num& rvalue) const;

public:	BC_Num();
	BC_Num(bc_num val) {
		num = val;
	}
	~BC_Num();

	inline void set(const char *val,int scale) {
		bc_str2num(&num,val,scale);
	}

	inline BC_Num& operator=(const BC_Num& rvalue) {
		bc_free_num(&num);
		num = bc_copy_num(rvalue.num);
		return *this;
	}

	BC_Num operator+(const BC_Num& rvalue) const;
	BC_Num operator-(const BC_Num& rvalue) const;

	void dump();
};


#endif // BCNUM_HPP

// End bcnum.hpp
