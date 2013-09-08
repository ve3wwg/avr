-- twi.ads - Sat Sep  7 23:17:20 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces, System;
use Interfaces;

package TWI is

    type Data_Array is array(Unsigned_16 range <>) of Unsigned_8;
    type TWI_Addr is new Unsigned_8 range 0..16#7F#;
    type TWI_Context is private;

    type TWI_Msg is
        record
            Addr :          TWI_Addr;
            Buffer :        System.Address;
            Length :        Natural;
            Write :         Boolean;
            Transferred :   Natural;
        end record;

    type TWI_Msg_Array is array (Unsigned_8 range <>) of TWI_Msg;

    procedure Initialize(Context : in out TWI_Context; Addr, Mask : TWI_Addr);

    procedure Send(
        Context :       in out  TWI_Context;
        Messages :      in out  TWI_Msg_Array;
        Failed :        out     Boolean
    );

private

    type Data_Ptr is access all Data_Array;

    type TWI_Context is
        record
            Addr :      TWI_Addr;           -- Our own address
            Busy :      Boolean;            -- True when I2C is active
        end record;

end TWI;
