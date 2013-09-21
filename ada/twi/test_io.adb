-- testio.adb - Thu Sep  5 22:41:48 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- IO Support for TestMain.adb
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;
with AVR.MCU;
with AVR.Wait;

with AVR.UART;
with AVR.Strings;

use AVR.Strings;
use Interfaces;

with TWI;

package body Test_IO is

    MCP23017 :  constant TWI.Slave_Addr   := 16#20#;

    IODIRA :    constant Unsigned_8 := 16#00#;
    IODIRB :    constant Unsigned_8 := 16#01#;
    IOCON :     constant Unsigned_8 := 16#0A#;

    IOCON_CFG : constant Unsigned_8 := 16#00#;  -- Bank=0
    IODIR_CFG : constant Unsigned_8 := 16#00#;  -- Outputs

    procedure CRLF is
    begin
        AVR.UART.Put(Character'Val(16#0D#));
        AVR.UART.Put(Character'Val(16#0A#));
    end CRLF;

    -- Put one character, translating NL to CRLF
    procedure Put(Ch : Character) is
    begin
        if Character'Pos(Ch) = 16#0A# then
            CRLF;
        else
            AVR.UART.Put(Ch);
        end if;
    end Put;

    -- Put one text line with CRLF
    procedure Put(S : AVR_String) is
    begin
        for X in S'Range loop
            Put(S(X));
        end loop;
    end Put;

    procedure Put_Pstr(S : PStr) is
    begin
        for X in S'Range loop
            Put(S(X));
        end loop;
    end Put_Pstr;

    -- Put one text line with CRLF
    procedure Put_Line(S : AVR_String) is
    begin
        for X in S'Range loop
            Put(S(X));
        end loop;
        AVR.UART.CRLF;
    end Put_Line;

    procedure Put_Status is
        S : AVR_String(1..2);
    begin
        Put("Status: ");
        TWI.R_Status(S);
        Put_Line(S);
    end Put_Status;

    procedure X_Status is
        Buf : AVR_String(1..60);
    begin
        TWI.XStatus(Buf);
        Put_Line(Buf);
    end X_Status;

    procedure C_Status is
        Buf : AVR_String(1..2);
    begin
        TWI.CStatus(Buf);
        Put_Line(Buf);
        CRLF;
    end C_Status;

    procedure Put_Count is
        S : AVR_String(1..2);
    begin
        Put("Count: ");
        TWI.Report(S);
        Put_Line(S);
    end Put_Count;

--    procedure Put(Error : TWI.Error_Code) is
--    begin
--        case Error is
--        when TWI.No_Error =>
--            Put_Line("No_Error.");
--        when TWI.Busy =>
--            Put_Line("Busy");
--        when TWI.Invalid =>
--            Put_Line("Invalid");
--        when TWI.Capacity =>
--            Put_Line("Capacity");
--        when TWI.Invalid_Buffer =>
--            Put_Line("Invalid_Buffer");
--        when TWI.Bad_State =>
--            Put_Line("State.");
--        when TWI.SLA_NAK =>
--            Put_Line("SLA_NAK");
--        when TWI.Failed =>
--            Put_Line("Failed");
--        end case;        
--    end Put;

--    procedure Put_Error is
--        E : TWI.Error_Code := TWI.Get_Error;
--    begin
--        Put("Error: ");
--        Put(E);
--        CRLF;
--    end Put_Error;

    My_Buffer :    aliased TWI.Data_Array := (0..39 => 0);

    procedure Test is
        use AVR, AVR.Strings;
        use TWI;

        Test_Begins :   constant PStr := "Test Begins: ";
        Ready :         constant PStr := "Ready: ";
        Init_Msg :      constant PStr := "Init..";
        Mode_Msg :      constant PStr := "Mode: ";
        TWCR_Msg :      constant PStr := "TWCR: ";

        Buf_Ptr :   Data_Array_Ptr := My_Buffer'Access;
        Error :     Error_Code;
        Ch :        Character;
        Orig_First : Unsigned_16;
        A : Data_Array := ( IOCON, IOCON_CFG );
        B : Data_Array := ( IODIRA, IODIR_CFG );
        C : Data_Array := ( IODIRB, IODIR_CFG );
    begin

        AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);

        Put_Pstr(Test_Begins);
        CRLF;

        loop
            Put_Pstr(Ready);
            Ch := UART.Get;
            Put(Ch);
            CRLF;

            case Ch is
            when 'i' =>
                Put_PStr(Init_Msg);
                CRLF;
                TWI.Initialize(16#01#,0,Buf_Ptr);
                Clear(Error);
--                Put(Error);
--#            when 'c' =>
--#                TWI.Clear(Error);
--#--                Put(Error);
            when 'x' =>
                TWI.Write(MCP23017,A,Error);
--                Put(Error);
                TWI.Write(MCP23017,B(0..0),Error);
                TWI.Read(MCP23017,Orig_First,Error);
--                Put(Error);
--                    TWI.Write(MCP23017,B,Error);
--                    Put(Error);
--                    TWI.Write(MCP23017,C,Error);
--                    Put(Error);

                Master(Error);
--                Put(Error);
                Put_Count;
                Put_Status;
            when others =>
--                Put_Line("??");
--                Put_Error;
                Put_Count;
                Put_Status;
                Put_PStr(Mode_Msg);
                Put(TWI.Get_Mode);
                CRLF;

--                Put("TWCR:");
                Put_PStr(TWCR_Msg);
                C_Status;
                Put(" ");
                X_Status;
--                B := My_Buffer(Orig_First);
--                Put("B := ");
--                Put_U8(B);
--                CRLF;
            end case;
        end loop;

    end Test;

end Test_IO;
