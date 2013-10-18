# avrdude parameters for programming:

AVRDUDE_CONF=/opt/local/etc/avrdude.conf

#PGMR	= avrisp
PGMR	= arduino
PGPORT	= /dev/cu.usbserial-A6005XBY
#PGBAUD	= 19200
PGBAUD	= 115200

PGMPARMS= -C $(AVRDUDE_CONF) -c $(PGMR) -P $(PGPORT) -b $(PGBAUD)

# End
