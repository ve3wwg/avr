//////////////////////////////////////////////////////////////////////
// test2.cpp -- Simple LED test of the USB interface
// Date: Sat Jan 24 19:44:33 2015  (C) Warren W. Gay VE3WWG 
///////////////////////////////////////////////////////////////////////
//
// This test program:
//
//	1)  Enumerates devices and locates the Vendor and Product
//	2)  Then opens the device
//	3)  Turns off the remote device's LED (or on if active low)
//	4)  Sleeps 2 seconds
//	5)  Turns on the remote device's LED 
//	6)  Closes and exits.
//
///////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <assert.h>

#include <usb.h>

#define VEND_ID		0x16C0
#define PROD_ID		0x05DC

int
main(int argc,char **argv) {
	struct usb_bus *bus;
	struct usb_device *dev, *vusb_dev = 0;
	bool dev_found = false;		// True if enumeration discovered the device

	usb_init();             	// initialize libusb
	usb_find_busses();
	usb_find_devices();

	for ( bus=usb_get_busses(); bus; bus=bus->next ) {
		for( dev=bus->devices; dev; dev=dev->next ) {
			struct usb_device_descriptor& desc = dev->descriptor;

			printf("Device: %s %04x:%04x, manuf %u\n",
				dev->filename,
				desc.idVendor,
				desc.idProduct,
				desc.iManufacturer);

			if ( desc.idVendor == VEND_ID && desc.idProduct == PROD_ID ) {
				printf("  Device %s is the V-USB device!\n",
					dev->filename);
				vusb_dev = dev;
				dev_found = true;
			}
		}
	}

	if ( !dev_found ) {
		// Bail out if the device was not found:
		fprintf(stderr,"V-USB device was not found.\n");
		return 1;
	}

	//////////////////////////////////////////////////////////////
	// Open and communicate with the device
	//////////////////////////////////////////////////////////////

	usb_dev_handle *handle = usb_open(vusb_dev);

	if ( !handle ) {
		fprintf(stderr,"Unable to open device.\n");
		return 4;
	}

	printf("V-USB Device opened..\n");

	usb_set_configuration(handle,0);		// Using endpoint 0
	usb_claim_interface(handle,0);			// Claim it

	//////////////////////////////////////////////////////////////
	// wValue and wIndex can be any application specific data,
	// in addition to the data buffer (not used here). Here we
	// set wValue = 0, to turn off the remove LED
	//////////////////////////////////////////////////////////////

	printf("Sending to V-USB device..\n");

	int txbytes = usb_control_msg(
		handle,
		USB_TYPE_VENDOR|USB_RECIP_DEVICE|USB_ENDPOINT_OUT, // bRequestType
		1,			// bRequest
		0,	          	// wValue
		0, 	         	// wIndex
		0,			// pointer to buffer containing data (no data here)
		0,			// wLength (no data here)
		1000			// timeout ms
	);

	printf("Sent %d bytes: LED should be OFF.\n",txbytes);

	sleep(2);

	//////////////////////////////////////////////////////////////
	// Send wValue = 1 to turn on the remote LED
	//////////////////////////////////////////////////////////////

	txbytes = usb_control_msg(
		handle,
		USB_TYPE_VENDOR|USB_RECIP_DEVICE|USB_ENDPOINT_OUT, // bRequestType
		1,			// bRequest
		1,	          	// wValue
		0, 	         	// wIndex
		0,			// pointer to buffer containing data (no data here)
		0,			// wLength (no data here)
		1000			// timeout ms
	);

	printf("Sent %d bytes: LED should be ON again.\n",txbytes);

	//////////////////////////////////////////////////////////////
	// Release the V-USB device
	//////////////////////////////////////////////////////////////

	usb_release_interface(handle,0);
	usb_close(handle);

	return 0;
}

// End test2.cpp
