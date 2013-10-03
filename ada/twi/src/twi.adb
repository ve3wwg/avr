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

    ------------------------------------------------------------------
    -- Possible Prescale Choices
    ------------------------------------------------------------------

    Prescale : constant Data_Array := (
        0 => 1,
        1 => 4,
        2 => 16,
        3 => 64
    );

    ------------------------------------------------------------------
    -- For the given CPU clock and Bus Rate, return actual Clock rate
    -- for the prescale index and divisor used
    ------------------------------------------------------------------
    function Rate(CPU_Clock : Integer_32; Prescale_X, Divisor : Unsigned_8) return Integer_32 is
    begin
        return Integer_32(CPU_Clock) /
            (16 + 2 * Integer_32(Divisor) * Integer_32(Prescale(Unsigned_16(Prescale_X))));
    end Rate;

    ------------------------------------------------------------------
    -- For the given CPU clock and required I2C Bus clock, compute the
    -- best prescale index and divisor values
    ------------------------------------------------------------------
    procedure Divisors(CPU_Clock, Bus_Clock : Integer_32; Prescale_X, Divisor : out Unsigned_8) is
        N :         Integer_32;
        PX :        Unsigned_16;
        D :         Integer_32 := 0;
        Last_SCL :  Integer_32 := 0;
        SCL :       Integer_32;
    begin

        N := (Integer_32(CPU_Clock) - 16 * Integer_32(Bus_Clock)) / (2 * Integer_32(Bus_Clock));

        if N <= 0 then
            Prescale_X := Unsigned_8(Prescale'Last);
            Divisor    := 255;
            return;    -- Lowest possible clock setting
        end if;

        for X in Prescale'Range loop
            if N / Integer_32(Prescale(X)) <= 255 then
                if Last_SCL = 0 then
                    PX := X;
                    D := N / Integer_32(Prescale(PX));
                    Last_SCL := Integer_32(CPU_Clock) / (16 + 2 * N);
                else
                    SCL := Integer_32(CPU_Clock) / (16 + 2 * N);
                    if Abs(Last_SCL - Integer_32(Bus_Clock)) > Abs(SCL - Integer_32(Bus_Clock)) then
                        PX := X;
                        D := N / Integer_32(Prescale(PX));
                        Last_SCL := SCL;
                    end if; 
                end if;
            end if;
        end loop;

        if D > 0 then
            -- Best achievable parameters
            Prescale_X := Unsigned_8(PX);
            Divisor    := Unsigned_8(D);
        else
            -- Highest achievable rate
            Prescale_X  := Unsigned_8(Prescale'First);
            Divisor     := 1;
        end if;

    end Divisors;


    BV_I :          Boolean renames AVR.MCU.SREG_Bits(AVR.MCU.I_Bit);

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

    ------------------------------------------------------------------
    -- Module Operation Mode
    ------------------------------------------------------------------

    type Operation_Mode is (
        Idle,
        Master,
        Slave
    );

    ------------------------------------------------------------------
    -- Idle Routine is called in blocking Completion() calls
    ------------------------------------------------------------------

    Idle_Routine :          Idle_Proc;          -- Idle procedure
    Receiving_Routine :     Receiving_Proc;     -- Slave read procedure
    Transmitting_Routine :  Transmitting_Proc;  -- Slave write procedure
    EOT_Routine :           EOT_Proc;           -- End of Transmission procedure

    ------------------------------------------------------------------
    -- I2C Messages
    ------------------------------------------------------------------

    Xfer :          Xfer_Array_Ptr;             -- Transfer I/O messages
    Buf :           Data_Array_Ptr;             -- I/O buffer

    Xfer_X :        Unsigned_8 := 0;            -- Current I/O Request index
    Xfer_Buf_X :    Unsigned_16 := 0;           -- Current I/O buffer index
    Xfer_Error :    Error_Code := No_Error;     -- Transfer status

    Init :          Boolean := False;           -- True once initialized
    Stopped :       Boolean := False;           -- True when stopped

    Mode :          Operation_Mode := Idle;
    pragma Volatile(Mode);

    Listening :     Boolean := false;           -- True if Slave listening in Master mode

    ------------------------------------------------------------------
    -- Slave Mode Status
    ------------------------------------------------------------------

    Slave_Ack :     Boolean;                    -- True if we returned Ack
    Gen_Call :      Boolean;                    -- True if this is a general call
    Slave_Count :   Natural;                    -- Byte counter
    pragma volatile(Slave_Count);

    Data_Byte :     Unsigned_8;                 -- Read/Written byte
    pragma Volatile(Data_Byte);

    Exit_Requested: Boolean;                    -- True when we should exit slave mode
    pragma Volatile(Exit_Requested);

    ------------------------------------------------------------------
    -- Internal: Return the Relevant TWSR bits
    ------------------------------------------------------------------
    function Status return Unsigned_8 is
    begin
        return TWSR and 16#FC#;                 -- Exclude the prescaler bits 1..0
    end Status;

    pragma inline(Status);

    ------------------------------------------------------------------
    -- Internal: Start a I2C Transmission
    ------------------------------------------------------------------
    procedure TWI_Start is
        Start : constant Unsigned_8 := 2#1010_0101#;
    begin
        if Listening then
            TWCR := Start or 2#0100_0000#;      -- Or in TWEA bit
        else
            TWCR := Start;
        end if;
    end TWI_Start;

    pragma inline(TWI_Start);

    ------------------------------------------------------------------
    -- Internal: Stop an I2C Transmission
    ------------------------------------------------------------------
    procedure TWI_Stop is
        Stop : constant Unsigned_8 := 2#1101_0101#;
    begin
        Mode := Idle;
        if Listening then
            TWCR := Stop or 2#0100_0000#;       -- Or in TWEA bit
        else
            TWCR := Stop;
        end if;
    end TWI_Stop;

    pragma inline(TWI_Stop);

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
    procedure Initialize(Addr, Mask : Slave_Addr; Prescale, Divisor : Unsigned_8; General_Call : Boolean := true) is
        use AVR;
    begin

        if BV_TWEN then
            Reset;              -- Reset the hardware, if necessary
        end if;

        BV_TWIE := False;       -- First disable TWI peripheral
        BV_TWEA := False;       -- Disable EA
        BV_PRTWI := False;

        DD_C5 := DD_Input;
        BV_C5 := True;          -- Enable pullup
        DD_C4 := DD_Input;
        BV_C4 := True;          -- Enable pullup

        TWSR := Prescale;
        TWBR := Divisor;

        if General_Call then
            TWAR  := Shift_Left(Unsigned_8(Addr),1) or 1;
        else
            TWAR  := Shift_Left(Unsigned_8(Addr),1);
        end if;
        TWAMR := Shift_Left(Unsigned_8(Mask),1);    -- 1's indicate bits to ignore

        Mode    := Idle;
        Buf     := null;
        Xfer    := null;

        BV_TWIE := True;
        BV_TWEA := True;
        BV_I    := True;

        Init    := True;
        Listening := false;

        Idle_Routine := null;
        Receiving_Routine := null;
        Transmitting_Routine := null;
        EOT_Routine := null;

    end Initialize;

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

        if Xfer_Msg = null or else Buffer = null then
            Error := Invalid;
            return;
        end if;

        Listening := Receiving_Routine /= null or else Transmitting_Routine /= null;

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
            elsif Idle_Routine /= null then
                Idle_Routine.all;
            end if;
        end loop;

        -- Loop waiting for Stop bit to be sent
        while BV_TWSTO loop
            if not Block then
                Error := Busy;
                return;
            elsif Idle_Routine /= null then
                Idle_Routine.all;
            end if;
        end loop;

        Error := Xfer_Error;

    end Complete;

    ------------------------------------------------------------------
    -- Set Idle Procedure to be called while waiting for Master mode
    -- I/O to complete in procedure Complete().
    ------------------------------------------------------------------
    procedure Set_Idle_Proc(Proc : Idle_Proc) is
    begin
        Idle_Routine := Proc;
    end Set_Idle_Proc;

    ------------------------------------------------------------------
    -- Configure Callbacks for Slave I/O
    ------------------------------------------------------------------
    procedure Allow_Slave(Recv : Receiving_Proc; Xmit : Transmitting_Proc; EOT : EOT_Proc) is
    begin

        Receiving_Routine    := Recv;
        Transmitting_Routine := Xmit;
        EOT_Routine          := EOT;

    end Allow_Slave;

    ------------------------------------------------------------------
    -- Disable Slave Callbacks
    ------------------------------------------------------------------
    procedure Disable_Slave is
    begin

        Receiving_Routine    := null;
        Transmitting_Routine := null;
        EOT_Routine          := null;

    end Disable_Slave;

    ------------------------------------------------------------------
    -- Operate in Slave Mode until Exit_Slave is called
    ------------------------------------------------------------------
    procedure Slave is
    begin

        if not Init or Mode /= Idle then
            return;
        end if;

        case Status is
        when 16#F8# =>
            null;
        when 16#00# =>          -- Bus error
            TWI_Clear_Bus_Error;
        when others =>
            return;
        end case;

        Mode           := Slave;
        Exit_Requested := false;
        Listening      := true;
        TWCR           := 2#1100_0101#;

        loop
            exit when Mode /= Slave;
            exit when Exit_Requested;
            if Idle_Routine /= null then
                Idle_Routine.all;
            end if;
        end loop;

    end Slave;

    ------------------------------------------------------------------
    -- Request an exit from the Slave monitor loop
    ------------------------------------------------------------------
    procedure Exit_Slave is
    begin
        Exit_Requested := true;
    end Exit_Slave;

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

        case S is
        --------------------------------------------------------------
        -- Slave Receiving
        --------------------------------------------------------------
        when 16#60# | 16#68# | 16#70# | 16#78# => -- Own SLA+W Received, Ack to be returned
            Slave_Ack := true;
            Gen_Call  := S >= 16#70#;       -- True if this is due to a General Call address
            Slave_Count := 0;               -- Initialize our transaction byte count
            if Receiving_Routine /= null then
                TWCR := 2#1100_0101#;       -- ACK (we have software to receive)
            else
                TWCR := 2#1000_0101#;       -- NAK
            end if;
            return;

        when 16#80# | 16#90# =>             -- Previously addressed with SLA+W, data byte received, ACKed
            Data_Byte := TWDR;
            Gen_Call  := S = 16#90#;
            Slave_Ack := true;
            if Receiving_Routine /= null then
                Receiving_Routine.all(Slave_Count,Gen_Call,Data_Byte,Slave_Ack);
            else
                Slave_Ack := false;         -- No receiving routine
            end if;
            Slave_Count := Slave_Count + 1; -- 1 more byte received
            if Slave_Ack then
                TWCR := 2#1100_0101#;
            else
                TWCR := 2#1000_0101#;
            end if;
            return;

        when 16#88# | 16#98# =>             -- Prev addr SLA+W, data recvd, NAK returned
            Data_Byte := TWDR;
            Slave_Ack := false;             -- NAKed
            Gen_Call  := S = 16#98#;
            if Receiving_Routine /= null then
                Receiving_Routine.all(Slave_Count,Gen_Call,Data_Byte,Slave_Ack);
            end if;
            Slave_Count := Slave_Count + 1;
            TWCR := 2#1100_0101#;
            return;

        when 16#A0# =>                      -- Stop/Restart has been transmitted
            if EOT_Routine /= null then
                EOT_Routine.all(Slave_Count,true,Exit_Requested);
            end if;
            if not Exit_Requested then
                TWCR := 2#1100_0101#;       -- Switch to non-addressed, but SLA/GCA will be recognized
            else
                TWCR := 2#1000_0101#;       -- Switch to non-addressed, and SLA/GCA no longer recognized
            end if;                         -- ..and exit out of the Slave() call.
            return;

        --------------------------------------------------------------
        -- Slave Transmitting
        --------------------------------------------------------------
        when 16#A8# | 16#B0# =>
            Slave_Ack   := true;
            Slave_Count := 0;
            if S = 16#B0# then
                Mode := Slave;              -- Master mode lost arbitration
            end if;
            if Transmitting_Routine /= null then
                Transmitting_Routine.all(Slave_Count,Data_Byte,Slave_Ack);
                TWDR := Data_Byte;
            else
                TWDR := 16#FF#;
                Slave_Ack := false;
            end if;
            if Slave_ACK then
                TWCR := 2#1100_0101#;       -- + Send ACK
            else
                TWCR := 2#1000_0101#;       -- + Send NAK
            end if;
            return;
            
        when 16#B8# =>                      -- Data byte transmitted, ACK received
            Slave_Ack := true;
            if Transmitting_Routine /= null then
                Transmitting_Routine.all(Slave_Count,Data_Byte,Slave_Ack);
                TWDR := Data_Byte;
            else
                TWDR := 16#FF#;
                Slave_Ack := false;
            end if;
            Slave_Count := Slave_Count + 1;
            if Slave_ACK then
                TWCR := 2#1100_0101#;       -- + Send ACK
            else
                TWCR := 2#1000_0101#;       -- + Send NAK
            end if;
            return;

        when 16#C0# | 16#C8# =>             -- Last data byte transmitted, NAK
            if EOT_Routine /= null then
                EOT_Routine.all(Slave_Count,false,Exit_Requested);
            end if;
            TWCR := 2#1100_0101#;
            return;

        when others =>
            null;
        end case;

        case S is

        when 16#00# =>  -- Bus error
            Xfer_Error := Bus_Error;    -- Needs Reset
            Mode := Idle;
            Stopped := False;           -- Don't wait for stop status to change

        --------------------------------------------------------------
        -- Master Transmitting
        --------------------------------------------------------------

        when 16#08# | 16#10# =>                 -- Start/Repeated-start has been transmitted
            Xmit_SLA(Xfer(Xfer_X).Addr,Xfer(Xfer_X).Xfer);

        when 16#18# =>                          -- SLA+W has been transmitted and ACKed
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

        when 16#28# =>                          -- Data byte has been transmitted and ACKed
            if Xfer_Buf_X <= Xfer(Xfer_X).Last then
                TWDR := Buf(Xfer_Buf_X);        -- Send another byte
                TWCR := 2#1100_0101#;           -- Transmit
                Xfer_Buf_X := Xfer_Buf_X + 1;
            else
                Xfer_X := Xfer_X + 1;
                if Xfer_X <= Xfer'Last then
                    TWI_Start;                  -- Repeated start
                else
                    TWI_Stop;
                    Stopped := true;
                end if;
            end if;

        when 16#20# =>                          -- SLA+W transmitted but NAKed
            Xfer_Error := SLA_NAK;
            Stopped := True;
            TWI_Stop;

        when 16#30# =>                          -- Data byte has been transmitted and NAKed
            Xfer_X := Xfer_X + 1;
            if Xfer_X <= Xfer'Last then
                TWI_Start;                      -- Repeated start
            else
                TWI_Stop;
                Stopped := true;
            end if;

        when 16#38# =>                          -- Arbitration lost in SLA+W transmission
            TWI_Start;                          -- Try again

        --------------------------------------------------------------
        -- Master Receiving
        --------------------------------------------------------------

        when 16#40# =>                          -- SLA+R has been transmitted and ACKed
            Xfer_Buf_X := Xfer(Xfer_X).First;
            if Xfer_Buf_X < Xfer(Xfer_X).Last then
                TWCR := 2#1100_0101#;           -- More to follow this byte
            else
                TWCR := 2#1000_0101#;           -- Only read this 1 byte
            end if;

        when 16#48# =>                          -- SLA+R transmitted by NAKed
            Xfer_Error := SLA_NAK;
            Stopped := True;
            TWI_Stop;

        when 16#50# =>                          -- Byte received and ACKed
            Buf(Xfer_Buf_X) := TWDR;
            Xfer_Buf_X := Xfer_Buf_X + 1;
            if Xfer_Buf_X < Xfer(Xfer_X).Last then
                TWCR := 2#1100_0101#;           -- More to follow this byte
            else
                TWCR := 2#1000_0101#;           -- Read one last byte
            end if;

        when 16#58# =>                          -- Read byte with NAK
            Buf(Xfer_Buf_X) := TWDR;
            Xfer_X := Xfer_X + 1;
            if Xfer_X <= Xfer'Last then
                TWI_Start;                      -- Repeated start
            else
                TWI_Stop;
                Stopped := true;
            end if;

        when others =>
            Xfer_Error := Failed;
            Mode := Idle;

        end case;

    end ISR;

end TWI;
