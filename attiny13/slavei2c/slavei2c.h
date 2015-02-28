//////////////////////////////////////////////////////////////////////
// slavei2c.h -- Header file for Slave I2C Application
// Date: Fri Feb 27 18:54:57 2015   (C) Warren Gay ve3wwg
///////////////////////////////////////////////////////////////////////

#ifndef I2CSLAVE_H
#define I2CSLAVE_H

#define SVC_ACK		((uint8_t)1)	// Return ACK to slavei2c framework
#define SVC_NAK		((uint8_t)0)	// Return NAK to slavei2c framework

extern uint8_t i2caddr;			// Registered I2C address (shifted left 1 bit)
extern uint8_t i2crequ;			// Received I2C address and R/W bit

uint8_t svc_init();			// Returns configured slave address

uint8_t svc_start(uint8_t addr_rw);	// Start a slave transaction
uint8_t svc_write(uint8_t wrdata);	// Service a master write operation
uint16_t svc_read(void);		// Service a master read operation

void svc_ended(void);			// Called when a transaction ends/fails

#endif // I2CSLAVE_H

// End slavei2c.h
