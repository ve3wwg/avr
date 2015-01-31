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
	inline BC_Num(const BC_Num& other) { num = bc_copy_num(other.num); }
	inline BC_Num(bc_num val) { num = val; }
	BC_Num(const char *val);
	BC_Num(int val);
	~BC_Num();

	inline int scale() { return num->n_scale; }

	BC_Num& assign(const char *val);

	inline void assign(const char *val,int scale) {
		bc_str2num(&num,val,scale);
	}

	inline BC_Num& operator=(const BC_Num& rvalue) {
		bc_free_num(&num);
		num = bc_copy_num(rvalue.num);
		return *this;
	}

	inline BC_Num& operator=(int rvalue) {
		bc_int2num(&num,rvalue);
		return *this;
	}

	inline long as_long() {
		return bc_num2long(num);
	}

	bool operator!() const;
	bool is_near_zero(int scale) const;
	bool is_negative() const;

	BC_Num operator-() const;

	BC_Num operator+(const BC_Num& rvalue) const;
	BC_Num operator-(const BC_Num& rvalue) const;
	BC_Num operator*(const BC_Num& rvalue) const;
	BC_Num operator/(const BC_Num& rvalue) const;
	BC_Num operator%(const BC_Num& rvalue) const;
	BC_Num operator^(const BC_Num& rvalue) const;

	BC_Num div(const BC_Num& rvalue,int scale) const;
	BC_Num divmod(const BC_Num& divisor,BC_Num& mod,int scale) const;
	BC_Num raisemod(const BC_Num& exp,const BC_Num& mod,int scale) const;

	bool operator<(const BC_Num& rvalue) const;
	bool operator<=(const BC_Num& rvalue) const;
	bool operator==(const BC_Num& rvalue) const;
	bool operator!=(const BC_Num& rvalue) const;
	bool operator>=(const BC_Num& rvalue) const;
	bool operator>(const BC_Num& rvalue) const;

	BC_Num& operator++();
	BC_Num& operator--();

	BC_Num& operator+=(const BC_Num& rvalue);
	BC_Num& operator-=(const BC_Num& rvalue);
	BC_Num& operator*=(const BC_Num& rvalue);
	BC_Num& operator/=(const BC_Num& rvalue);
	BC_Num& operator%=(const BC_Num& rvalue);

	BC_Num& operator+=(int rvalue);
	BC_Num& operator-=(int rvalue);
	BC_Num& operator*=(int rvalue);
	BC_Num& operator/=(int rvalue);
	BC_Num& operator%=(int rvalue);

	BC_Num negate() const;

	BC_Num sin(const BC_Num& x,int scale);
	BC_Num atan(const BC_Num& x,int scale);

	void dump(const char *prefix=0) const;

	inline static BC_Num zero() { return BC_Num(bc_copy_num(_zero_)); }
	inline static BC_Num one()  { return BC_Num(bc_copy_num(_one_)); }
	inline static BC_Num two()  { return BC_Num(bc_copy_num(_two_)); }
};


#endif // BCNUM_HPP

// End bcnum.hpp
