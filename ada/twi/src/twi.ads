-- twi.ads - Sat Sep  7 23:17:20 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.Strings;
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

    type Slave_Addr is new Unsigned_8 range 0..16#7F#;

    type Data_Array is array(Unsigned_16 range <>) of Unsigned_8;
    type Data_Array_Ptr is access all Data_Array;

    type Xfer_Type is
        record
            Addr :          Slave_Addr;     -- Slave Address
            Write :         Boolean;        -- True for write, else read
            First :         Unsigned_16;    -- First buffer index
            Last :          Unsigned_16;    -- Last buffer index
            Count :         Unsigned_16;    -- Returned: Actual I/O count
        end record;

    type Xfer_Array is array(Unsigned_8 range <>) of Xfer_Type;
    type Xfer_Array_Ptr is access all Xfer_Array;

    procedure Reset;
    procedure Initialize(Addr, Mask : Slave_Addr);
    procedure Master(Xfer_Msg : Xfer_Array_Ptr; Buffer : Data_Array_Ptr; Error : out Error_Code);

    function Get_Error return Error_Code;
    function Get_Mode return Character;

    procedure XStatus(Str : out AVR.Strings.AVR_String);
    procedure To_Hex(U : Unsigned_8; S : out AVR.Strings.AVR_String);

end TWI;
