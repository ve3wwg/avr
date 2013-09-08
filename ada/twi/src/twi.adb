-- twi.adb - Sat Sep  7 23:17:47 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.MCU;
with System.Memory;

package body TWI is

    TWCR :          Unsigned_8 renames AVR.MCU.TWCR;
    TWSR :          Unsigned_8 renames AVR.MCU.TWSR;
    TWAR :          Unsigned_8 renames AVR.MCU.TWAR;
    TWBR :          Unsigned_8 renames AVR.MCU.TWBR;
    TWDR :          Unsigned_8 renames AVR.MCU.TWDR;
    TWAMR :         Unsigned_8 renames AVR.MCU.TWAMR;

    -- TWCR -- Control Register
    BV_TWIE :       Boolean renames AVR.MCU.TWCR_Bits(AVR.MCU.TWIE_Bit);
    BV_TWEN :       Boolean renames AVR.MCU.TWCR_Bits(AVR.MCU.TWEN_Bit);
    BV_TWWC :       Boolean renames AVR.MCU.TWCR_Bits(AVR.MCU.TWWC_Bit);
    BV_TWSTO :      Boolean renames AVR.MCU.TWCR_Bits(AVR.MCU.TWSTO_Bit);
    BV_TWSTA :      Boolean renames AVR.MCU.TWCR_Bits(AVR.MCU.TWSTA_Bit);
    BV_TWEA :       Boolean renames AVR.MCU.TWCR_Bits(AVR.MCU.TWEA_Bit);
    BV_TWINT :      Boolean renames AVR.MCU.TWCR_Bits(AVR.MCU.TWINT_Bit);

    -- Allocate Array_Data
    procedure Alloc_Data(Size : System.Memory.size_t; Buf_Addr : out System.Address) is
    begin
        Buf_Addr := System.Memory.Alloc(Size);
    end Alloc_Data;

    -- Free Allocated Buffer
    procedure Free_Data(Buf_Addr : in out System.Address) is
    begin
        System.Memory.Free(Buf_Addr);
        Buf_Addr := System.Null_Address;
    end Free_Data;

    -- Return the Relevant TWSR bits
    function Status return Unsigned_8 is
        S : Unsigned_8 := TWSR and 16#FC#;  -- Exclude the prescaler bits 1..0
    begin
        return S;
    end Status;

    -- Initialize the Context
    procedure Initialize(Context : in out TWI_Context; Addr : TWI_Addr) is
    begin

        Context.Addr := Addr;
        Context.Busy := False;

    end Initialize;

    -- Master Send Request
    procedure Send(
        Context :       in out  TWI_Context;
        Slave :         in      TWI_Addr;
        Data :          in      Data_Array
    ) is
        use System;
    begin
        
        pragma Assert(Context.Busy = False);
        pragma Assert(Context.Buf_Addr = System.Null_Address);

        Alloc_Data(Data'Length,Context.Buf_Addr);

        Context.Peer := Slave;
        Context.Busy := True;

    end Send;

end TWI;


