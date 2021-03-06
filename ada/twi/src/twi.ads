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

    ------------------------------------------------------------------
    -- Error Codes
    ------------------------------------------------------------------

    type Error_Code is (
        No_Error,           -- No error (Success)
        Busy,               -- TWI is busy with a current request
        Invalid,            -- Invalid request
        SLA_NAK,            -- SLA+W received a NAK
        Bus_Error,          -- A bus error occured
        Failed              -- Failed for an unknown reason
    );

    type Slave_Addr is new Unsigned_8 range 0..16#7F#;

    ------------------------------------------------------------------
    -- All I2C Data Transfers occur in/out of this Data_Array type
    ------------------------------------------------------------------

    type Data_Array is array(Unsigned_16 range <>) of Unsigned_8;
    type Data_Array_Ptr is access all Data_Array;

    ------------------------------------------------------------------
    -- I2C Transfer Kind
    ------------------------------------------------------------------

    type Xfer_Kind is (
        Write,              -- Write 1 or more bytes
        Null_Write,         -- Issue Restart immediately after SLA+W (write 0 bytes: First,Last ignored)
        Read                -- Read 1 or more bytes
    );

    ------------------------------------------------------------------
    -- I2C Transaction Message
    ------------------------------------------------------------------

    type Xfer_Type is
        record
            Addr :          Slave_Addr;     -- Slave Address
            Xfer :          Xfer_Kind;      -- Read/Write
            First :         Unsigned_16;    -- First buffer index
            Last :          Unsigned_16;    -- Last buffer index
        end record;

    type Xfer_Array is array(Unsigned_8 range <>) of Xfer_Type;
    type Xfer_Array_Ptr is access all Xfer_Array;

    ------------------------------------------------------------------
    -- Initialization
    ------------------------------------------------------------------

    procedure Divisors(CPU_Clock, Bus_Clock : Integer_32; Prescale_X, Divisor : out Unsigned_8);
    procedure Initialize(Addr, Mask : Slave_Addr; Prescale, Divisor : Unsigned_8; General_Call : Boolean := true);

    function Rate(CPU_Clock : Integer_32; Prescale_X, Divisor : Unsigned_8) return Integer_32;

    ------------------------------------------------------------------
    -- Slave Mode I/O
    ------------------------------------------------------------------
    
    type Receiving_Proc is access
        procedure(Count : Natural; Gen_Call : Boolean; Byte : Unsigned_8; Ack : in out Boolean);
    type Transmitting_Proc is access
        procedure(Count : Natural; Byte : out Unsigned_8; Ack : in out Boolean);
    type EOT_Proc is access
        procedure(Count : Natural; Receiving : Boolean; Exit_Req : in out Boolean);

    procedure Allow_Slave(Recv : Receiving_Proc; Xmit : Transmitting_Proc; EOT : EOT_Proc);
    procedure Slave;
    procedure Exit_Slave;
    procedure Disable_Slave;

    ------------------------------------------------------------------
    -- Master Mode I/O
    ------------------------------------------------------------------
    procedure Master(Xfer_Msg : Xfer_Array_Ptr; Buffer : Data_Array_Ptr; Error : out Error_Code);
    procedure Complete(Error : out Error_Code; Block : Boolean := true);

    ------------------------------------------------------------------
    -- Idle Procedure (called during interrupt driven Master Mode I/O)
    ------------------------------------------------------------------
    type Idle_Proc is access procedure;

    procedure Set_Idle_Proc(Proc : Idle_Proc);

end TWI;
