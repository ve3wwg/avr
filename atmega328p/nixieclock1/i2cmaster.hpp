//////////////////////////////////////////////////////////////////////
// i2cmaster.hpp -- I2C-master.h
// Date: Tue Feb 17 20:14:50 2015   (C) Warren Gay ve3wwg
//
// Copied and Derived from:
//   https://github.com/devthrash/I2C-master-lib
///////////////////////////////////////////////////////////////////////

#ifndef I2CMASTER_HPP
#define I2CMASTER_HPP

#define I2C_WRITE	0
#define I2C_READ	1

void I2C_init(void);

uint8_t I2C_start(uint8_t address);

uint8_t I2C_write(uint8_t data);

uint8_t I2C_read_ack(void);
uint8_t I2C_read_nack(void);

void I2C_stop(void);

#endif // I2CMASTER_HPP

// End i2cmaster.hpp

