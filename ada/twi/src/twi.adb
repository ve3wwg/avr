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

    SREG :          Unsigned_8 renames AVR.MCU.SREG;
    BV_I :          Boolean renames AVR.MCU.SREG_Bits(AVR.MCU.I_Bit);

    PRR :           Unsigned_8 renames AVR.MCU.PRR;
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
        Master_Transmit,
        Master_Receive,
        Slave_Transmit,
        Slave_Receive
    );

    type TWI_State is (
        Idle,
        Started,
        SLA,
        Data,
        Stopped
    );

    Local_Addr :    TWI_Addr := 0;
    Addr_Mask :     TWI_Addr := 0;
    Mode :          Operation_Mode := Idle;
    State :         TWI_State := Idle;
--    Messages :      Msg_Array_Ptr;

    -- Return the Relevant TWSR bits
    function Status return Unsigned_8 is
        S : Unsigned_8 := TWSR and 16#FC#;  -- Exclude the prescaler bits 1..0
    begin
        return S;
    end Status;

    procedure TWI_Start is
    begin
        BV_TWIE  := True;
        BV_TWEN  := True;
        BV_TWSTA := True;
        BV_TWINT := True;
    end TWI_Start;

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
        State := Idle;
--        Messages := null;

    end Initialize;

    type Msg_Type is
        record
            Addr :          TWI_Addr;
            Write :         Boolean;
            First :         Unsigned_16;
            Last :          Unsigned_16;
        end record;
    
    type Msg_Array is array (Unsigned_8 range <>) of Msg_Type;
    type Msg_Array_Ptr is access all Msg_Array;

    N_Requests :    Unsigned_8 := 0;
    Req_X :         Unsigned_16 := 0;
    Requests :      Msg_Array(0..12);

    procedure Clear(Error : out Error_Code) is
    begin
        if State /= Idle and Mode /= Idle then
            Error      := Busy;
        else
            Error      := No_Error;
            N_Requests := 0;
            Req_X      := 0;
        end if;
    end Clear;

    procedure Request(Addr : TWI_Addr; Bytes: Unsigned_16; Write : Boolean; Error : out Error_Code) is
    begin
        if State /= Idle and Mode /= Idle then
            Error := Busy;
        else
            if N_Requests < Requests'Length then
                Requests(N_Requests).Addr := Addr;
                Requests(N_Requests).Write := Write;
                Requests(N_Requests).First := Req_X;
                Req_X := Req_X + Bytes;
                Requests(N_Requests).Last  := Req_X - 1;
            else
                Error := Capacity;
            end if;
        end if;
    end Request;

    procedure Transfer(Buffer : in out Data_Array; Error : out Error_Code) is
    begin
        if State /= Idle and Mode /= Idle then
            Error := Busy;
            return;
        elsif N_Requests <= 0 then
            Error := Invalid;
            return;
        end if;

        Error := No_Error;


    end Transfer;


--        case Status is
--        when 16#F8# =>      -- No state info (or between states)
--            null;
--        when 16#00# =>      -- Bus error
--            BV_TWSTO := True;
--            BV_TWINT := True;
--            if Status /= 16#F8# then
--                Error := Bad_State;
--                return;
--            end if;
--        when others =>
--            Error := Busy;
--            return;
--        end case;
--
--        Mode := Master_Transmit;
--        Messages := Send.Messages;
--        State := Started;
--        TWI_Start;
--
--    end Send;

--    procedure Query(S : out String) is
--        U : Unsigned_8 := Unsigned_8(Count);
--    begin
--        To_Hex(U,S);
--    end Query;
--
--    procedure Query_SREG(S : out String) is
--    begin
--        To_Hex(SREG,S);
--    end Query_SREG;
--
--    procedure Query_TWSR(S : out String) is
--    begin
--        To_Hex(TWSR,S);
--    end Query_TWSR;
--
--    procedure Query_TWCR(S : out String) is
--    begin
--        To_Hex(TWCR,S);
--    end Query_TWCR;

    procedure ISR;
    pragma Machine_Attribute(
        Entity => ISR,
        Attribute_Name => "signal"
    );
    pragma Export(C,ISR,AVR.MCU.Sig_TWI_String);

    procedure ISR is
    begin

        Count := Count + 1;

        BV_TWINT := True;       -- Clear interrupt

        case Mode is
        when Master_Transmit =>
            null;
        when Master_Receive =>
            null;
        when Slave_Transmit =>
            null;
        when Slave_Receive =>
            null;
        when Idle =>
            null;
        end case;        

    end ISR;

end TWI;
