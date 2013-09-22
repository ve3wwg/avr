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

--    pragma Linker_Options("-lavrada");

    Statuses : Data_Array := ( 0..63 => 0 );
    pragma Volatile(Statuses);

    SX_First :  Unsigned_16 := Statuses'First + 5;
    SX :        Unsigned_16 := SX_First;
    pragma Volatile(SX);

    Count :         Unsigned_8 renames Statuses(Statuses'First);
    Report_TWCR :   Unsigned_8 renames Statuses(Statuses'First+1);
    Report_Status : Unsigned_8 renames Statuses(Statuses'First+2);
    Msg_Index :     Unsigned_8 renames Statuses(Statuses'First+3);
    Buf_Index :     Unsigned_8 renames Statuses(Statuses'First+4);

    function To_Nibble_Hex(U : Unsigned_8) return Character is
    begin
        if U <= 16#09# then
            return Character'Val(U+Character'Pos('0'));
        else
            return Character'Val(U+Character'Pos('A')-10);
        end if;
    end To_Nibble_Hex;

    procedure To_Hex(U : Unsigned_8; S : out AVR_String) is
        Upper, Lower : Unsigned_8;
    begin
        Lower := U and 16#0F#;
        Upper := Shift_Right(U and 16#F0#,4);
        S(S'First) := To_Nibble_Hex(Upper);
        S(S'First+1) := To_Nibble_Hex(Lower);
    end to_hex;

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
    pragma Volatile(Mode);

    ------------------------------------------------------------------
    -- I2C Messages
    ------------------------------------------------------------------

    Xfer :          Xfer_Array_Ptr;             -- Transfer I/O messages
    Buf :           Data_Array_Ptr;             -- I/O buffer

    N_Requests :    constant Unsigned_8 := 12;  -- Max # of requests at one time
    Xfer_X :        Unsigned_8 := 0;            -- Current I/O Request index
    pragma Volatile(Xfer_X);
    Xfer_Buf_X :    Unsigned_16 := 0;           -- Current I/O buffer index
    pragma Volatile(Xfer_Buf_X);

    Xfer_Error :    Error_Code := No_Error;     -- Transfer status
    pragma Volatile(Xfer_Error);

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
    -- API: Initialize the I2C Peripheral 
    ------------------------------------------------------------------
    procedure Initialize(Addr, Mask : Slave_Addr) is
        use AVR;
    begin

        if BV_TWEN then
            Reset;
        end if;

        BV_TWIE := False;
        BV_TWEA := False;

        Clear_Info;

        BV_PRTWI := False;

        DD_C5 := DD_Input;
        BV_C5 := True;          -- Enable pullup

        DD_C4 := DD_Input;
        BV_C4 := True;          -- Enable pullup

        TWSR  := 0;             -- Prescale = x 1
        TWBR  := 8;
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

        Mode := Idle;

    end Initialize;

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
    -- Initiate a Master Mode Transaction
    ------------------------------------------------------------------
    procedure Master(Xfer_Msg : Xfer_Array_Ptr; Buffer : Data_Array_Ptr; Error : out Error_Code) is
    begin

        if Mode /= Idle then
            Error := Busy;
            return;
        end if;

        Clear_Info;

        if Xfer_Msg = null or else Buffer = null then
            Error := Invalid;
            return;
        end if;

        Xfer := Xfer_Msg;
        Buf  := Buffer;
        Xfer_X := Xfer'First;        
        Error := No_Error;

        for X in Xfer'Range loop
            Xfer(X).Count := 0;
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

        case Status is
        when 16#F8# =>
            Mode := Master;
            TWI_Start;
        when 16#00# =>          -- Bus error
--            TWI_Clear_Bus_Error;
            Mode := Master;
--            TWI_Start;
        when others =>
            Mode := Idle;
            Error := Failed;            
        end case;

    end Master;

    ------------------------------------------------------------------
    -- Internal (ISR): Transmit a Master Mode Byte
    ------------------------------------------------------------------
    procedure Xmit_Byte is
        Cmd : Unsigned_8 := 2#1100_0101#;
    begin

        if Xfer_Buf_X <= Xfer(Xfer_X).Last then
            -- Continue current data transmission
            TWDR := Buf(Xfer_Buf_X);
            Xfer_Buf_X := Xfer_Buf_X + 1;
            TWCR := Cmd;
        else
            -- End current transmission
            Xfer_X := Xfer_X + 1;
            if Xfer_X <= Xfer'Last then
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

        if Xfer_Buf_X <= Xfer(Xfer_X).Last then
            Buf(Xfer_Buf_X) := TWDR;
            if Xfer_Buf_X < Xfer(Xfer_X).Last then
                Cmd := Cmd or EA;   -- Ack this xfer
            end if;
            Xfer_Buf_X := Xfer_Buf_X + 1;
            TWCR := Cmd;
        else
            -- End current receive
            Xfer_X := Xfer_X + 1;
            if Xfer_X <= Xfer'Last then
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

        case S is

        when 16#00# =>  -- Bus error
--            TWI_Clear_Bus_Error;
--            TWI_Start;
            null;

        when 16#38# =>  -- Arbitration lost in SLA+W transmission
            TWI_Start;  -- Try again

        when 16#08# | 16#10# =>  -- Start/Repeated-start has been transmitted
            TWI_Send_SLA(Xfer(Xfer_X).Addr,Xfer(Xfer_X).Write);

        when 16#20# =>  -- SLA+W transmitted but NAKed
            return;
            Xfer_Error := SLA_NAK;
            TWI_Stop;

        when 16#48# =>  -- SLA+R transmitted by NAKed
            return;
            Xfer_Error := SLA_NAK;
            TWI_Stop;

        when 16#18# =>  -- SLA+W has been transmitted and ACKed
            Xfer_Buf_X := Xfer(Xfer_X).First;
            Xmit_Byte;

        when 16#28# =>  -- Data byte has been transmitted and ACKed
            Xmit_Byte;

        when 16#30# =>  -- Data byte has been transmitted and NAKed
            Xfer_X := Xfer_X + 1;
            if Xfer_X <= Xfer'Last then
                TWI_Start;      -- This will be a repeated start
            else
                TWI_Stop;
            end if;

        when 16#40# =>  -- SLA+R has been transmitted and ACKed
            Xfer_Buf_X := Xfer(Xfer_X).First;
            Recv_Byte;

        when 16#50# | 16#58# =>
            Recv_Byte;

        when 16#F8# =>
            Mode := Idle;

        when others =>
            Mode := Idle;
        end case;

        Msg_Index := Unsigned_8(Xfer_X);
        Buf_Index := Unsigned_8(Xfer_Buf_X);

    end ISR;

    function Get_Error return Error_Code is
    begin
        return Xfer_Error;
    end Get_Error;

    procedure XStatus(Str : out AVR_String) is
        U : Unsigned_8;
        S : AVR_String(1..2);
        Y : Unsigned_8 := Str'First;
    begin
        Report_TWCR   := TWCR;
        Report_Status := Status;
        Str := ( ' ', others => ' ' );
        for X in Statuses'Range loop
            exit when Y > Str'Last;
            if X >= SX then
                Str(Y) := ';';
                return;
            end if;
            U := Statuses(X);
            To_Hex(U,S);
            Str(Y) := S(S'First);
            Str(Y+1) := S(S'Last);
            Str(Y+2) := ' ';
            Y := Y + 3;
        end loop;

    end XStatus;

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

end TWI;
