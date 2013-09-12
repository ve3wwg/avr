-- twi.ads - Sat Sep  7 23:17:20 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;
use Interfaces;

package TWI is

    type Error_Code is (
        No_Error,           -- No error (Success)
        Invalid_Buffer,     -- Invalid or null buffer pointer
        Busy,               -- TWI is busy with a current request
        Capacity,           -- Too many Requests/Bytes
        Invalid,            -- Invalid request
        Bad_State,          -- Unable to ready the TWI controller
        SLA_NAK,            -- SLA+W received a NAK
        Failed              -- Failed for an unknown reason
    );

    type TWI_Addr is new Unsigned_8 range 0..16#7F#;

    type Data_Array is array(Unsigned_16 range <>) of Unsigned_8;
    type Data_Array_Ptr is access all Data_Array;

    procedure Initialize(Addr, Mask : TWI_Addr);

    procedure Clear(Error : out Error_Code);
    procedure Request(Addr : TWI_Addr; Bytes : Unsigned_16; Write : Boolean; Error : out Error_Code);
    procedure Indexes(First, Last : out Unsigned_16);
    procedure Indexes(X : Unsigned_8; First, Last : out Unsigned_16);
    procedure Master(Buffer : in out Data_Array; Error : out Error_Code);

end TWI;
