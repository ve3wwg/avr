//////////////////////////////////////////////////////////////////////
// bf.hpp -- BigFloat from the bc number support
// Date: Tue Feb  3 22:43:22 2015   (C) Warren Gay ve3wwg
///////////////////////////////////////////////////////////////////////

#ifndef BF_HPP
#define BF_HPP

#include "number.hpp"

class BF {
	int		exponent : 16;	// Value of the exponent
	int		mantissa : 16;	// Length-1 of the mantissa in digits
	bc_num		num;

protected:
	BF(bc_num num,unsigned mant);
	BF addsub(const BF& rvalue,int sub) const;

public:	BF(unsigned mant=32);
	BF(int intval,unsigned mant=32);
	BF(const char *val,unsigned mant=32);
	BF(const BF& other);

	BF& shift(int exponent);

	BF& normalize();

	BF& assign(const char *val);

	BF operator+(const BF& rvalue) const;
	BF operator-(const BF& rvalue) const;

	char *as_string();
};

#endif // BF_HPP

// End bf.hpp
