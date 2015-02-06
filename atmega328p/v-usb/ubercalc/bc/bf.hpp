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
	int compare(const BF& rvalue) const;

public:	BF(unsigned mant=32);
	BF(int intval,unsigned mant=32);
	BF(const char *val,unsigned mant=32);
	BF(const BF& other);

	BF& normalize();

	BF& assign(const char *val);
	BF& negate();

	bool operator!() const;
	BF operator-() const;

	bool operator<(const BF& rvalue) const;
	bool operator<=(const BF& rvalue) const;
	bool operator==(const BF& rvalue) const;
	bool operator!=(const BF& rvalue) const;
	bool operator>=(const BF& rvalue) const;
	bool operator>(const BF& rvalue) const;

	BF& operator++();
	BF& operator--();

	BF operator++(int);
	BF operator--(int);

	BF& operator=(const BF& rvalue);

	BF operator+(const BF& rvalue) const;
	BF operator-(const BF& rvalue) const;
	BF operator*(const BF& rvalue) const;
	BF operator/(const BF& rvalue) const;
	BF operator^(const BF& rvalue) const;

	BF& operator+=(const BF& rvalue);
	BF& operator-=(const BF& rvalue);
	BF& operator*=(const BF& rvalue);
	BF& operator/=(const BF& rvalue);

	BF& operator=(int rvalue);

	BF operator+(int rvalue) const;
	BF operator-(int rvalue) const;
	BF operator*(int rvalue) const;
	BF operator/(int rvalue) const;

	BF& operator+=(int rvalue);
	BF& operator-=(int rvalue);
	BF& operator*=(int rvalue);
	BF& operator/=(int rvalue);

	long as_long() const;
	char *as_string() const;

	// Static 
	static BF truncate(const BF& x);
	static BF abs(const BF& x);
	static BF pi(int mantissa);
#if 0
	static BF sin(const BF& x);
//	static BF sqrt(const BF& x);
	static BF cos(const BF& x);
	static BF tan(const BF& x);
#endif
	static BF pi_range(const BF& x);	// coax x into pi > x > -pi
};

#endif // BF_HPP

// End bf.hpp
