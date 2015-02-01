//////////////////////////////////////////////////////////////////////
// bcnum.hpp -- BC class
// Date: Thu Jan 29 21:32:54 2015   (C) Warren Gay ve3wwg
///////////////////////////////////////////////////////////////////////

#ifndef BCNUM_HPP
#define BCNUM_HPP

#include "number.hpp"


class BC {
	bc_num		num;

protected:
	int common_scale(const BC& rvalue) const;

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

	BC sin(const BC& x,int scale) const;
	BC cos(const BC& x,int scale) const;
	BC atan(const BC& x,int scale) const;

	void dump(const char *prefix=0) const;

	inline static BC zero() { return BC(bc_copy_num(_zero_)); }
	inline static BC one()  { return BC(bc_copy_num(_one_)); }
	inline static BC two()  { return BC(bc_copy_num(_two_)); }
};


#endif // BCNUM_HPP

// End bcnum.hpp
