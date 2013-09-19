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

use AVR.Strings;

package body TWI is

    pragma Linker_Options("-lavrada");



    Statuses : Data_Array := ( 0..16 => 0 );
    SX : Unsigned_16 := Statuses'First;



    procedure To_Hex(U : Unsigned_8; S : out AVR_String) is
    begin
        AVR.Int_Img.U8_Hex_Img(U,S);
    end to_hex;

    Count : Unsigned_8 := 0;
    pragma Volatile(Count);

    procedure Report(S : out AVR_String) is
    begin
        To_Hex(Count,S);
    end Report;

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

    ------------------------------------------------------------------
    -- Configuration
    ------------------------------------------------------------------

    Local_Addr :    Slave_Addr := 0;
    Addr_Mask :     Slave_Addr := 0;
    Mode :          Operation_Mode := Idle;
    Prev_Status :   Unsigned_8 := 0;
    Last_Status :   Unsigned_8 := 0;

    pragma Volatile(Mode);

    function Get_Mode return Character is
    begin
        case Mode is
        when Idle =>
            return 'I';
        when Master =>
            return 'M';
        when Slave =>
            return 'S';
        end case;
    end Get_Mode;

    ------------------------------------------------------------------
    -- I2C Messages
    ------------------------------------------------------------------

    type Msg_Type is
        record
            Addr :          Slave_Addr;
            Write :         Boolean;
            First :         Unsigned_16;
            Last :          Unsigned_16;
            Failed :        Boolean;
        end record;
    
    type Msg_Array is array (Unsigned_8 range <>) of Msg_Type;
    type Msg_Array_Ptr is access all Msg_Array;

    Buf :           Data_Array_Ptr;

    N_Requests :    constant Unsigned_8 := 12;  -- Max # of requests at one time
    Request_X :     Unsigned_8 := 0;            -- Current Request index
    Xfer_X :        Unsigned_8 := 0;            -- Current I/O Request index
    Req_Buf_X :     Unsigned_16 := 0;           -- Current buffer index
    Xfer_Buf_X :    Unsigned_16 := 0;           -- Current I/O buffer index
    Requests :      Msg_Array(0..N_Requests-1); -- List of requests
    Xfer_Error :    Error_Code := No_Error;     -- Transfer status


    ------------------------------------------------------------------
    -- Return the Relevant TWSR bits
    ------------------------------------------------------------------
    function Status return Unsigned_8 is
    begin
        return TWSR and 16#FC#;                 -- Exclude the prescaler bits 1..0
    end Status;

    ------------------------------------------------------------------
    -- Start a I2C Transmission
    ------------------------------------------------------------------
    procedure TWI_Start is
        Start : constant Unsigned_8 := 2#1110_0101#;
    begin
        TWCR := Start;
    end TWI_Start;

    ------------------------------------------------------------------
    -- Stop an I2C Transmission
    ------------------------------------------------------------------
    procedure TWI_Stop is
        Stop : constant Unsigned_8 := 2#1101_0101#;
    begin
        Mode := Idle;
        TWCR := Stop;
    end TWI_Stop;

    ------------------------------------------------------------------
    -- Clear TWI Peripheral out of Bus Error State
    ------------------------------------------------------------------
    procedure TWI_Clear_Bus_Error is
    begin
        loop
            BV_TWSTA := False;
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

    ------------------------------------------------------------------
    -- Transmit the SLA+W
    ------------------------------------------------------------------
    procedure TWI_Send_SLA(Addr : Slave_Addr; Write : Boolean) is
        SLA_R : Unsigned_8 := Shift_Left(Unsigned_8(Addr),1);
        Cmd   : Unsigned_8 := 2#1100_0101#;
    begin
        if not Write then
            SLA_R := SLA_R or 1;
        end if;
        TWDR := SLA_R;
        TWCR := Cmd;
    end TWI_Send_SLA;

    ------------------------------------------------------------------
    -- API - Initialize the I2C Peripheral 
    ------------------------------------------------------------------
    procedure Initialize(Addr, Mask : Slave_Addr; Buffer : Data_Array_Ptr) is
        use AVR;
    begin

        BV_PRTWI := False;

        DD_C5 := DD_Input;
        BV_C5 := True;          -- Enable pullup

        DD_C4 := DD_Input;
        BV_C4 := True;          -- Enable pullup

        TWSR  := 0;             -- Prescale = x 1
        TWBR  := 8;
        TWAR  := Unsigned_8(Addr);
        TWAMR := Unsigned_8(Mask);

        BV_TWIE := True;
        BV_TWEA := True;
        BV_I    := True;

        Local_Addr := Addr;
        Addr_Mask := Mask;
        Mode := Idle;
        Buf := Buffer;

        Request_X := 0;
        Req_Buf_X := 0;
        Mode      := Idle;

    end Initialize;

    ------------------------------------------------------------------
    -- Clear last completed request
    ------------------------------------------------------------------
    procedure Clear(Error : out Error_Code) is
    begin
        Error := Invalid;
        if Mode /= Idle then
            Error      := Busy;
        else
            Error      := No_Error;
            Request_X  := 0; 
            Req_Buf_X  := 0;
            Mode       := Idle;
        end if;
    end Clear;

    ------------------------------------------------------------------
    -- Make a Master I/O Request
    ------------------------------------------------------------------
    procedure Write(Addr : Slave_Addr; Data : Data_Array; Error : out Error_Code) is
    begin
        if Mode /= Idle then
            Error := Busy;
        else
            if Request_X <= Requests'Last then
                Requests(Request_X).Addr := Addr;
                Requests(Request_X).Write := True;
                Requests(Request_X).First := Req_Buf_X;

                for X in Data'Range loop
                    Buf(Req_Buf_X) := Data(X);
                    Req_Buf_X := Req_Buf_X + 1;
                end loop;
                Requests(Request_X).Last  := Req_Buf_X - 1;
                Request_X := Request_X + 1;
                Error := No_Error;
            else
                Error := Capacity;
            end if;
        end if;
    end Write;

    ------------------------------------------------------------------
    -- Return the buffer indexes of the Xth Transfer "Request"
    ------------------------------------------------------------------
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

    ------------------------------------------------------------------
    -- Return the buffer indexes of the LAST Transfer Request
    ------------------------------------------------------------------
    procedure Indexes(First, Last : out Unsigned_16) is
        Last_X : Unsigned_8 := Request_X - 1;
    begin
        Indexes(Last_X,First,Last);
    end Indexes;

    ------------------------------------------------------------------
    -- Perform a blocking I/O request
    ------------------------------------------------------------------
    procedure Master(Error : out Error_Code) is
    begin
        if Mode /= Idle then
            Error := Busy;
            return;
        elsif Buf = null then
            Error := Invalid;
            return;
        elsif Request_X <= Requests'First then
            Error := Invalid;
            return;
        elsif Requests(Requests'First).First < Buf'First then
            Error := Capacity;
            return;
        elsif Requests(Request_X-1).Last > Buf'Last then
            Error := Capacity;
            return;
        end if;

        Error := No_Error;
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
            Error := Failed;            
            return;
        end case;

    end Master;

    ------------------------------------------------------------------
    -- Transmit a Master Mode Byte
    ------------------------------------------------------------------
    procedure Xmit_Byte is
        Cmd : Unsigned_8 := 2#1100_0101#;
    begin

        if Xfer_Buf_X <= Requests(Xfer_X).Last then
            -- Continue current data transmission
            TWDR := Buf(Xfer_Buf_X);
            Xfer_Buf_X := Xfer_Buf_X + 1;
            TWCR := Cmd;
        else
            -- End current transmission
            Requests(Xfer_X).Failed := False;
            Xfer_X := Xfer_X + 1;
            if Xfer_X < Request_X then
                TWI_Start;  -- Repeated start
            else
                TWI_Stop;   -- End of transmission
            end if;
        end if;

    end Xmit_Byte;

    ------------------------------------------------------------------
    -- Receive a Master Mode Byte
    ------------------------------------------------------------------
    procedure Recv_Byte is
        Cmd : Unsigned_8          := 2#1000_0101#;
        EA :  constant Unsigned_8 := 2#0100_0000#;
    begin

        if Xfer_Buf_X <= Requests(Xfer_X).Last then
            Buf(Xfer_Buf_X) := TWDR;
            if Xfer_Buf_X >= Requests(Xfer_X).Last then
                Cmd := Cmd xor EA;   -- This last byte will be NAKed
            end if;
            Xfer_Buf_X := Xfer_Buf_X + 1;
            TWCR := Cmd;
        else
            -- End current receive
            Xfer_X := Xfer_X + 1;
            if Xfer_X < Request_X then
	        TWI_Start;
            else
                TWI_Stop;
            end if;
        end if;

    end Recv_Byte;

    ------------------------------------------------------------------
    -- Interrupt Service Routine Attributes
    ------------------------------------------------------------------

    procedure ISR;
    pragma Machine_Attribute(
        Entity => ISR,
        Attribute_Name => "signal"
    );
    pragma Export(C,ISR,AVR.MCU.Sig_TWI_String);

    ------------------------------------------------------------------
    -- The Interrupt Service Routine
    ------------------------------------------------------------------

    procedure ISR is
        S : Unsigned_8 := Status;
    begin

        Count := Count + 1;

        if SX <= Statuses'Last then
            Statuses(SX) := S;
            SX := SX + 1;
        end if;

        Prev_Status := Last_Status;
        Last_Status := S;

        case S is
        when 16#00# =>  -- Bus error
            TWI_Clear_Bus_Error;
            TWI_Start;
        when 16#38# =>  -- Arbitration lost in SLA+W transmission
            TWI_Start;  -- Try again
        when 16#08# | 16#10# =>  -- Start/Repeated-start has been transmitted
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
            Mode := Idle;
        end case;

    end ISR;

    procedure R_Status(S : out AVR_String) is
        T : Unsigned_8 := Status;
    begin
        To_Hex(T,S);
    end R_Status;

    function Get_Error return Error_Code is
    begin
        return Xfer_Error;
    end Get_Error;

    procedure PStatus(S : out AVR_String) is
    begin
        To_Hex(Prev_Status,S);
    end PStatus;

    procedure LStatus(S : out AVR_String) is
    begin
        To_Hex(Last_Status,S);
    end LStatus;

    procedure XStatus(Str : out AVR_String) is
        U : Unsigned_8;
        S : AVR_String(1..2);
        Y : Unsigned_8 := Str'First;
    begin
        Str := ( ' ', others => ' ' );
        for X in Statuses'Range loop
            if X >= SX then
                Str(Y) := '.';
                return;
            end if;
            U := Statuses(X);
            To_Hex(U,S);
            Str(Y) := S(S'First);
            Str(Y+1) := S(S'Last);
            Str(Y+2) := ',';
            Y := Y + 3;
        end loop;
    end XStatus;

end TWI;
