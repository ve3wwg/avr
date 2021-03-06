//////////////////////////////////////////////////////////////////////
// bc.hpp -- BC class
// Date: Thu Jan 29 21:32:54 2015   (C) Warren Gay ve3wwg
///////////////////////////////////////////////////////////////////////

#ifndef BC_HPP
#define BC_HPP

#include "number.hpp"

class BF;

class BC {
	friend class BF;

	bc_num		num;

public:	BC();
	inline BC(const BC& other) { num = bc_copy_num(other.num); }
	BC(const BC& other,int scale);
	inline BC(bc_num val) { num = val; }
	BC(const char *val);
	BC(int val);
	~BC();

	inline int scale() { return num->n_scale; }

	BC& assign(const char *val);
	BC& rescale(int scale);

	inline void assign(const char *val,int scale) {
		bc_str2num(&num,val,scale);
	}

	inline BC& operator=(const BC& rvalue) {
		bc_free_num(&num);
		num = bc_copy_num(rvalue.num);
		return *this;
	}

	inline BC& operator=(int rvalue) {
		bc_int2num(&num,rvalue);
		return *this;
	}

	inline long as_long() {
		return bc_num2long(num);
	}

	inline char *as_string() {
		return bc_num2str(num);
	}

	bool operator!() const;
	bool is_near_zero(int scale) const;
	bool is_negative() const;

	BC operator-() const;

	BC operator+(const BC& rvalue) const;
	BC operator-(const BC& rvalue) const;
	BC operator*(const BC& rvalue) const;
	BC operator/(const BC& rvalue) const;
	BC operator%(const BC& rvalue) const;
	BC operator^(const BC& rvalue) const;

	BC div(const BC& rvalue,int scale) const;
	BC divmod(const BC& divisor,BC& mod,int scale) const;
	BC raisemod(const BC& exp,const BC& mod,int scale) const;

	bool operator<(const BC& rvalue) const;
	bool operator<=(const BC& rvalue) const;
	bool operator==(const BC& rvalue) const;
	bool operator!=(const BC& rvalue) const;
	bool operator>=(const BC& rvalue) const;
	bool operator>(const BC& rvalue) const;

	BC& operator++();
	BC& operator--();

	BC operator++(int);
	BC operator--(int);

	BC& operator+=(const BC& rvalue);
	BC& operator-=(const BC& rvalue);
	BC& operator*=(const BC& rvalue);
	BC& operator/=(const BC& rvalue);
	BC& operator%=(const BC& rvalue);

	BC& operator+=(int rvalue);
	BC& operator-=(int rvalue);
	BC& operator*=(int rvalue);
	BC& operator/=(int rvalue);
	BC& operator%=(int rvalue);

	BC negate() const;

	static BC pi(int scale);
	static BC sqrt(const BC& x,int scale);
	static BC sin(const BC& x,int scale);
	static BC cos(const BC& x,int scale);
	static BC tan(const BC& x,int scale);

	static BC e(const BC& x,int scale);
	static BC ln(const BC& x,int scale);

	static BC arcsin(const BC& x,int scale);
	static BC arccos(const BC& x,int scale);
	static BC arctan(const BC& x,int scale);
	static BC arccot(const BC& x,int scale);
	static BC arcsec(const BC& x,int scale);
	static BC arccsc(const BC& x,int scale);

	static BC degrees(const BC& radians,int scale);
	static BC radians(const BC& degress,int scale);

	void dump(const char *prefix=0) const;

	inline static BC zero() { return BC(bc_copy_num(_zero_)); }
	inline static BC one()  { return BC(bc_copy_num(_one_)); }
	inline static BC two()  { return BC(bc_copy_num(_two_)); }
};


#endif // BC_HPP

// End bc.hpp
