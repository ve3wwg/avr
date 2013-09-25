-- twi.adb - Sat Sep  7 23:17:47 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.MCU;
with AVR.Wait;
with AVR.Strings;

use AVR.Strings;

package body TWI is

    Statuses : Data_Array := ( 0..63 => 0 );    -- For debugging
    pragma Volatile(Statuses);

    SX_First :  Unsigned_16 := Statuses'First + 5;
    SX :        Unsigned_16 := SX_First;
    pragma Volatile(SX);

    Count :         Unsigned_8 renames Statuses(Statuses'First);
    Report_TWCR :   Unsigned_8 renames Statuses(Statuses'First+1);
    Report_Status : Unsigned_8 renames Statuses(Statuses'First+2);
    Msg_Index :     Unsigned_8 renames Statuses(Statuses'First+3);
    Buf_Index :     Unsigned_8 renames Statuses(Statuses'First+4);

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

    Local_Addr :    Slave_Addr := 16#7F#;
    Addr_Mask :     Slave_Addr := 0;

    ------------------------------------------------------------------
    -- I2C Messages
    ------------------------------------------------------------------

    Xfer :          Xfer_Array_Ptr;             -- Transfer I/O messages
    Buf :           Data_Array_Ptr;             -- I/O buffer

    Xfer_X :        Unsigned_8 := 0;            -- Current I/O Request index
    pragma Volatile(Xfer_X);

    Xfer_Buf_X :    Unsigned_16 := 0;           -- Current I/O buffer index
    pragma Volatile(Xfer_Buf_X);

    Xfer_Error :    Error_Code := No_Error;     -- Transfer status
    pragma Volatile(Xfer_Error);

    Init :          Boolean := False;           -- True once initialized
    Stopped :       Boolean := False;           -- True when stopped

    Mode :          Operation_Mode := Idle;
    pragma Volatile(Mode);

    ------------------------------------------------------------------
    -- Internal: Return the Relevant TWSR bits
    ------------------------------------------------------------------
    function Status return Unsigned_8 is
    begin
        return TWSR and 16#FC#;                 -- Exclude the prescaler bits 1..0
    end Status;

    ------------------------------------------------------------------
    -- Internal: Start a I2C Transmission
    ------------------------------------------------------------------
    procedure TWI_Start is
        Start : constant Unsigned_8 := 2#1110_0101#;
    begin
        TWCR := Start;
    end TWI_Start;

    ------------------------------------------------------------------
    -- Internal: Stop an I2C Transmission
    ------------------------------------------------------------------
    procedure TWI_Stop is
        Stop : constant Unsigned_8 := 2#1101_0101#;
    begin
        Mode := Idle;
        TWCR := Stop;
    end TWI_Stop;

    ------------------------------------------------------------------
    -- Internal: Clear TWI Peripheral out of Bus Error State
    ------------------------------------------------------------------
    procedure TWI_Clear_Bus_Error is
    begin
        TWI_Stop;
        for Count in 0..1000 loop
            if Status = 16#F8# then
                return;
            end if;
        end loop;
    end TWI_Clear_Bus_Error;

    ------------------------------------------------------------------
    -- Internal: Transmit the SLA+W
    ------------------------------------------------------------------
    procedure Xmit_SLA(Addr : Slave_Addr; Xfer : Xfer_Kind) is
        SLA_R : Unsigned_8 := Shift_Left(Unsigned_8(Addr),1);
        Cmd   : Unsigned_8 := 2#1100_0101#;
    begin
        case Xfer is
            when Read =>
                SLA_R := SLA_R or 1;
            when Write | Null_Write =>
                null;
        end case;
        TWDR := SLA_R;
        TWCR := Cmd;
    end Xmit_SLA;

    ------------------------------------------------------------------
    -- Clear Debug Info
    ------------------------------------------------------------------
    procedure Clear_Info is
    begin
        Statuses := ( 0, others => 0 );
        SX       := SX_First;
        Msg_Index := Xfer_X;
        Buf_Index := Unsigned_8(Xfer_Buf_X);
        Count    := 0;
    end Clear_Info;

    ------------------------------------------------------------------
    -- Internal: Delay n millisconds
    ------------------------------------------------------------------
    procedure Delay_MS(MS : Natural) is
    begin
        for X in 1..MS loop
            AVR.Wait.Wait_4_Cycles(8000);
        end loop;
    end Delay_MS;

    ------------------------------------------------------------------
    -- Internal: Reset/recover TWI Peripheral
    ------------------------------------------------------------------
    procedure Reset is
        Stop_No_Int :   constant Unsigned_8 := 2#1101_0100#;
        EN_Only :       constant Unsigned_8 := 2#0000_0100#;
    begin
        if BV_TWINT or else BV_TWSTA then
            -- Interrupt pending
            TWCR := Stop_No_Int;
            Delay_MS(31);
            TWCR := EN_Only;
            Delay_MS(31);
            TWCR := Stop_No_Int;
            Delay_MS(31);
        end if;
    end Reset;

    ------------------------------------------------------------------
    -- API: Initialize the I2C Peripheral 
    ------------------------------------------------------------------
    procedure Initialize(Addr, Mask : Slave_Addr; Rate : I2C_Rate := I2C_400khz) is
        use AVR;
    begin

        if BV_TWEN then
            Reset;              -- Reset the hardware, if necessary
        end if;

        BV_TWIE := False;
        BV_TWEA := False;

        Clear_Info;

        BV_PRTWI := False;

        DD_C5 := DD_Input;
        BV_C5 := True;          -- Enable pullup

        DD_C4 := DD_Input;
        BV_C4 := True;          -- Enable pullup

        case Rate is
            when I2C_400khz =>
                TWSR := 0;      -- Prescale x 1
                TWBR := 8;
            when I2C_100khz =>
                TWSR := 1;      -- Prescale x 4
                TWBR := 18;
        end case;

        TWAR  := Unsigned_8(Addr);
        TWAMR := Unsigned_8(Mask);

        Local_Addr := Addr;
        Addr_Mask  := Mask;
        Mode       := Idle;

        Buf        := null;
        Xfer       := null;

        BV_TWIE := True;
        BV_TWEA := True;
        BV_I    := True;

        Mode    := Idle;
        Init    := True;

    end Initialize;

    ------------------------------------------------------------------
    -- Set a Custom I2C Clock Rate
    ------------------------------------------------------------------
    procedure Custom_Rate(Divisor : Unsigned_8; Prescale : Prescale_Type) is
    begin
        case Prescale is
            when By_1 =>
                TWSR := 0;      -- Prescale x 1
            when By_4 =>
                TWSR := 1;
            when By_16 =>
                TWSR := 2;
            when By_64 =>
                TWSR := 3;
        end case;
        TWBR := Divisor;
    end Custom_Rate;

    ------------------------------------------------------------------
    -- Initiate a Master Mode Transaction
    ------------------------------------------------------------------
    procedure Master(Xfer_Msg : Xfer_Array_Ptr; Buffer : Data_Array_Ptr; Error : out Error_Code) is
    begin

        if not Init then
            Error := Invalid;
            return;
        end if;

        if Mode /= Idle then
            Error := Busy;
            return;
        end if;

        Clear_Info;

        if Xfer_Msg = null or else Buffer = null then
            Error := Invalid;
            return;
        end if;

        Xfer    := Xfer_Msg;
        Buf     := Buffer;
        Xfer_X  := Xfer'First;        
        Error   := No_Error;

        for X in Xfer'Range loop
            if Xfer(X).First < Buf'First or else Xfer(X).Last > Buf'Last then
                Error := Invalid;
            elsif Xfer(X).Last < Xfer(X).First then
                Error := Invalid;
            end if;
        end loop;

        if Error /= No_Error then
            return;
        end if;

        Xfer_Buf_X := Xfer(Xfer_X).First;
        Stopped := False;

        case Status is
        when 16#F8# =>
            Mode := Master;
            TWI_Start;
        when 16#00# =>          -- Bus error
            TWI_Clear_Bus_Error;
            Mode := Master;
            TWI_Start;
        when others =>
            Mode := Idle;
            Error := Failed;            
        end case;

    end Master;

    ------------------------------------------------------------------
    -- Wait until completion
    ------------------------------------------------------------------

    procedure Complete(Error : out Error_Code; Block : Boolean := true) is
    begin

        -- Loop while I/O pending
        while Mode /= Idle loop
            if not Block then
                Error := Busy;
                return;
            end if;
        end loop;

        -- Loop waiting for Stop bit to be sent
        while BV_TWSTO loop
            if not Block then
                Error := Busy;
                return;
            end if;
        end loop;

        Error := Xfer_Error;

    end Complete;

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

        case S is

        when 16#00# =>  -- Bus error
            Xfer_Error := Bus_Error;
            Mode := Idle;
            Stopped := False;   -- Don't wait for stop status to change

        when 16#38# =>  -- Arbitration lost in SLA+W transmission
            TWI_Start;  -- Try again

        when 16#08# | 16#10# =>  -- Start/Repeated-start has been transmitted
            Xmit_SLA(Xfer(Xfer_X).Addr,Xfer(Xfer_X).Xfer);

        when 16#20# =>  -- SLA+W transmitted but NAKed
            Xfer_Error := SLA_NAK;
            Stopped := True;
            TWI_Stop;

        when 16#48# =>  -- SLA+R transmitted by NAKed
            Xfer_Error := SLA_NAK;
            Stopped := True;
            TWI_Stop;

        when 16#18# =>  -- SLA+W has been transmitted and ACKed
            if Xfer(Xfer_X).Xfer /= Null_Write then
                Xfer_Buf_X := Xfer(Xfer_X).First;
                TWDR := Buf(Xfer_Buf_X);        -- Send first byte
                Xfer_Buf_X := Xfer_Buf_X + 1;
                TWCR := 2#1100_0101#;           -- Transmit
            else
                Xfer_X := Xfer_X + 1;
                if Xfer_X <= Xfer'Last then
                    TWI_Start;                  -- Repeated start
                else
                    TWI_Stop;
                    Stopped := true;
                end if;
            end if;

        when 16#28# =>  -- Data byte has been transmitted and ACKed
            if Xfer_Buf_X <= Xfer(Xfer_X).Last then
                TWDR := Buf(Xfer_Buf_X);    -- Send another byte
                TWCR := 2#1100_0101#;       -- Transmit
                Xfer_Buf_X := Xfer_Buf_X + 1;
            else
                Xfer_X := Xfer_X + 1;
                if Xfer_X <= Xfer'Last then
                    TWI_Start;              -- Repeated start
                else
                    TWI_Stop;
                    Stopped := true;
                end if;
            end if;

        when 16#30# =>  -- Data byte has been transmitted and NAKed
            Xfer_X := Xfer_X + 1;
            if Xfer_X <= Xfer'Last then
                TWI_Start;                  -- Repeated start
            else
                TWI_Stop;
                Stopped := true;
            end if;

        when 16#40# =>  -- SLA+R has been transmitted and ACKed
            Xfer_Buf_X := Xfer(Xfer_X).First;
            if Xfer_Buf_X < Xfer(Xfer_X).Last then
                TWCR := 2#1100_0101#;       -- More to follow this byte
            else
                TWCR := 2#1000_0101#;       -- Only read this 1 byte
            end if;

        when 16#50# =>
            Buf(Xfer_Buf_X) := TWDR;
            Xfer_Buf_X := Xfer_Buf_X + 1;
            if Xfer_Buf_X < Xfer(Xfer_X).Last then
                TWCR := 2#1100_0101#;       -- More to follow this byte
            else
                TWCR := 2#1000_0101#;       -- Read one last byte
            end if;

        when 16#58# =>
            Buf(Xfer_Buf_X) := TWDR;
            Xfer_X := Xfer_X + 1;
            if Xfer_X <= Xfer'Last then
                TWI_Start;                  -- This will be a repeated start
            else
                TWI_Stop;
                Stopped := true;
            end if;

        when others =>
            Xfer_Error := Failed;
            Mode := Idle;

        end case;

        Msg_Index := Unsigned_8(Xfer_X);
        Buf_Index := Unsigned_8(Xfer_Buf_X);

    end ISR;

    ------------------------------------------------------------------
    -- Debugging Access
    ------------------------------------------------------------------

    procedure Get_Status(Stat : out Data_Array; X : out Unsigned_16) is
        K : Unsigned_16 := Statuses'First;
    begin
        X             := SX;
        Report_TWCR   := TWCR;
        Report_Status := Status;

        for J in Stat'Range loop
            exit when K > Statuses'Last;
            Stat(J) := Statuses(K);
            K := K + 1;
        end loop;

    end Get_Status;

end TWI;
