-- twi.adb - Sat Sep  7 23:17:47 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.MCU;
with AVR.Strings;
with AVR.Int_Img;

with System;

package body TWI is

    procedure to_hex(U : Unsigned_8; S : out String) is
        use AVR.Strings;
        A : AStr2;
    begin
        AVR.Int_Img.U8_Hex_Img(U,A);
        for X in A'Range loop
            S(Natural(X)) := A(X);
        end loop;
    end to_hex;

    Count :         Natural := 0;
    pragma Volatile(Count);

--  SREG :          Unsigned_8 renames AVR.MCU.SREG;
    BV_I :          Boolean renames AVR.MCU.SREG_Bits(AVR.MCU.I_Bit);

--  PRR :           Unsigned_8 renames AVR.MCU.PRR;
    BV_PRTWI :      Boolean renames AVR.MCU.PRR_Bits(AVR.MCU.PRTWI_Bit);

    DD_C5 :         Boolean renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC5_Bit);
    DD_C4 :         Boolean renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC4_Bit);
    BV_C5 :         Boolean renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC5_Bit);
    BV_C4 :         Boolean renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC4_Bit);

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

    type Operation_Mode is (
        Idle,
        Master,
        Slave
    );

    Local_Addr :    TWI_Addr := 0;
    Addr_Mask :     TWI_Addr := 0;
    Mode :          Operation_Mode := Idle;

    pragma Volatile(Mode);

    -- Return the Relevant TWSR bits
    function Status return Unsigned_8 is
        S : Unsigned_8 := TWSR and 16#FC#;  -- Exclude the prescaler bits 1..0
    begin
        return S;
    end Status;

    procedure TWI_Start is
    begin
        BV_TWIE  := True;
        BV_TWEA  := True;
        BV_TWEN  := True;
        BV_TWSTA := True;
        BV_TWINT := True;
    end TWI_Start;

    procedure TWI_Stop is
    begin
        BV_TWEA  := True;
        BV_TWSTO := True;
        BV_TWINT := True;
    end TWI_Stop;

    -- Clear TWI Peripheral out of Bus Error State
    procedure TWI_Clear_Bus_Error is
    begin
        loop
            BV_TWSTO := True;
            BV_TWINT := True;
            exit when Status = 16#F8#;

            for Count in 0..1000 loop
                if Status = 16#F8# then
                    return;
                end if;
            end loop;
        end loop;        
    end TWI_Clear_Bus_Error;

    -- Transmit the SLA+W
    procedure TWI_Send_SLA(Addr : TWI_Addr; Write : Boolean) is
        SLA_W : Unsigned_8 := Shift_Left(Unsigned_8(Addr),1);
    begin
        if Write then
            SLA_W := SLA_W or 1;
        end if;
        TWDR := SLA_W;
        BV_TWINT := True;
    end TWI_Send_SLA;

    -- Initialize the Context
    procedure Initialize(Addr, Mask : TWI_Addr) is
        use AVR;
    begin

        BV_PRTWI := False;

        DD_C5 := DD_Input;
        BV_C5 := True;          -- Enable pullup

        DD_C4 := DD_Input;
        BV_C4 := True;

        TWSR  := 0;     -- Prescale = x 1
        TWBR  := 8;
        TWAR  := Unsigned_8(Addr);
        TWAMR := Unsigned_8(Mask);

        BV_TWIE := True;
        BV_TWEA := True;
        BV_I    := True;

        Local_Addr := Addr;
        Addr_Mask := Mask;
        Mode := Idle;

    end Initialize;

    type Msg_Type is
        record
            Addr :          TWI_Addr;
            Write :         Boolean;
            First :         Unsigned_16;
            Last :          Unsigned_16;
            Failed :        Boolean;
        end record;
    
    type Msg_Array is array (Unsigned_8 range <>) of Msg_Type;
    type Msg_Array_Ptr is access all Msg_Array;

    Buf_Ptr :       System.Address;
    IO_Buffer :     Data_Array(0..1024);
    for IO_Buffer'Address use Buf_Ptr;

    N_Requests :    constant Unsigned_8 := 12;  -- Max # of requests at one time
    Request_X :     Unsigned_8 := 0;            -- Current Request index
    Xfer_X :        Unsigned_8 := 0;            -- Current I/O Request index
    Req_Buf_X :     Unsigned_16 := 0;           -- Current buffer index
    Xfer_Buf_X :    Unsigned_16 := 0;           -- Current I/O buffer index
    Requests :      Msg_Array(0..N_Requests-1); -- List of requests
    Xfer_Error :    Error_Code := No_Error;     -- Transfer status


    procedure Clear(Error : out Error_Code) is
    begin
        if Mode /= Idle then
            Error      := Busy;
        else
            Error      := No_Error;
            Request_X  := 0; 
            Req_Buf_X  := 0;
            Mode       := Idle;
        end if;
    end Clear;


    procedure Request(Addr : TWI_Addr; Bytes: Unsigned_16; Write : Boolean; Error : out Error_Code) is
    begin
        if Mode /= Idle then
            Error := Busy;
        else
            if Request_X <= Requests'Last then
                Requests(Request_X).Addr := Addr;
                Requests(Request_X).Write := Write;
                Requests(Request_X).First := Req_Buf_X;
                Req_Buf_X := Req_Buf_X + Bytes;
                Requests(Request_X).Last  := Req_Buf_X - 1;
                Request_X := Request_X + 1;
                Error := No_Error;
            else
                Error := Capacity;
            end if;
        end if;
    end Request;


    -- Return the buffer indexes of the Xth Transfer "Request"
    procedure Indexes(X : Unsigned_8; First, Last : out Unsigned_16) is
    begin
        if X >= Requests'First and X <= Requests'Last then
            First := Requests(X).First;
            Last  := Requests(X).Last;
        else
            First := 0;
            Last  := 0;
        end if;
    end Indexes;


    -- Return the buffer indexes of the LAST Transfer Request
    procedure Indexes(First, Last : out Unsigned_16) is
        Last_X : Unsigned_8 := Request_X - 1;
    begin
        Indexes(Last_X,First,Last);
    end Indexes;


    -- Perform a blocking I/O request
    procedure Master(Buffer : in out Data_Array; Error : out Error_Code) is
    begin
        if Mode /= Idle then
            Error := Busy;
            return;
        elsif Request_X <= Requests'First then
            Error := Invalid;
            return;
        elsif Buffer'First /= Requests(Requests'First).First or else Buffer'Last < Req_Buf_X then
            Error := Capacity;
            return;
        end if;

        Error := No_Error;
        Buf_Ptr := Buffer'Address;

        Mode := Master;
        Xfer_X := Requests'First;
        Xfer_Buf_X := Requests(Xfer_X).First;
        Xfer_Error := No_Error;

        case Status is
        when 16#F8# =>
            TWI_Start;
        when 16#00# =>          -- Bus error
            TWI_Clear_Bus_Error;
            TWI_Start;
        when others =>
            Mode := Idle;
            Error := Failed;            
            return;
        end case;

        loop
            exit when Mode = Idle;
        end loop;

    end Master;


    procedure Xmit_Byte is
    begin

        if Xfer_Buf_X <= Requests(Xfer_X).Last then
            -- Continue current data transmission
            TWDR := IO_Buffer(Xfer_Buf_X);
            Xfer_Buf_X := Xfer_Buf_X;
            BV_TWINT := True;
        else
            -- End current transmission
            Requests(Xfer_X).Failed := False;
            Xfer_X := Xfer_X + 1;
            if Xfer_X < Request_X then
                -- Start next transmission/reception
                TWI_Start;  -- Repeated start
            else
                -- We're all done now
                TWI_Stop;   -- End of transmission
            end if;
        end if;

    end Xmit_Byte;

    procedure Recv_Byte is
    begin

        if Xfer_Buf_X <= Requests(Xfer_X).Last then
            -- Continue to receive data
            IO_Buffer(Xfer_Buf_X) := TWDR;
            if Xfer_Buf_X >= Requests(Xfer_X).Last then
                BV_TWEA := True;    -- This last byte will be NAKed
            end if;
            Xfer_Buf_X := Xfer_Buf_X + 1;
            BV_TWINT := True;
        else
            -- End current receive
            Xfer_X := Xfer_X + 1;
            if Xfer_X > Request_X then
                -- Start next transmission/reception
	        TWI_Start;
            else
                TWI_Stop;
            end if;
        end if;

    end Recv_Byte;


    procedure ISR;
    pragma Machine_Attribute(
        Entity => ISR,
        Attribute_Name => "signal"
    );
    pragma Export(C,ISR,AVR.MCU.Sig_TWI_String);

    procedure ISR is
    begin

        BV_TWINT := True;       -- Clear interrupt

        if Request_X <= Requests'First then
            return;             -- Spurious
        elsif Mode = Idle then
            return;             -- Spurious
        end if;

        case Status is
        when 16#00# =>  -- Bus error
            TWI_Clear_Bus_Error;
            TWI_Start;
        when 16#38# =>  -- Arbitration lost in SLA+W transmission
            TWI_Start;  -- Try again
        when 16#08# | 16#10# =>  -- Start/Repeated-start has been transmitted
            Requests(Xfer_X).Failed := False;
            Xfer_Buf_X := Requests(Xfer_X).First;
            TWI_Send_SLA(Requests(Xfer_X).Addr,Requests(Xfer_X).Write);
        when 16#20# =>  -- SLA+W transmitted but NAKed
            Requests(Xfer_X).Failed := True;
            Xfer_Error := SLA_NAK;
            TWI_Stop;
        when 16#48# =>  -- SLA+R transmitted by NAKed
            Requests(Xfer_X).Failed := True;
            Xfer_Error := SLA_NAK;
            TWI_Stop;
        when 16#18# =>  -- SLA+W has been transmitted and ACKed
            Xmit_Byte;
        when 16#28# =>  -- Data byte has been transmitted and ACKed
            Xmit_Byte;
        when 16#30# =>  -- Data byte has been transmitted and NAKed
            Requests(Xfer_X).Last := Xfer_Buf_X;
            Xfer_X := Xfer_X + 1;
            if Xfer_X < Request_X then
                TWI_Start;      -- This will be a repeated start
            else
                TWI_Stop;
            end if;
        when 16#40# =>  -- SLA+R has been transmitted and ACKed
            Recv_Byte;
        when 16#50# | 16#58# =>
            Recv_Byte;
        when 16#F8# =>
            Mode := Idle;
        when others =>
            null;           -- Spurious or unsupported
        end case;

    end ISR;

end TWI;
