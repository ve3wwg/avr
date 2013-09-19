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

    IODIR :     constant Unsigned_8 := 16#00#;
    IOCON :     constant Unsigned_8 := 16#0A#;

    IOCON_CFG : constant Unsigned_8 := 16#00#;
    IODIR_CFG : constant Unsigned_8 := 16#00#;

    procedure CRLF renames AVR.UART.CRLF;

    -- Put one character, translating NL to CRLF
    procedure Put(Ch : Character) is
    begin
        if Character'Pos(Ch) = 16#0A# then
            AVR.UART.Put(Character'Val(16#0D#));
            AVR.UART.Put(Character'Val(16#0A#));
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

    procedure Put_Count is
        S : AVR_String(1..2);
    begin
        Put("Count: ");
        TWI.Report(S);
        Put_Line(S);
    end Put_Count;

    procedure Last_Status is
        S : AVR_String(1..2);
    begin
        Put("Last_Status: ");
        TWI.PStatus(S);
        Put(S);
        Put(" ");
        TWI.LStatus(S);
        Put_Line(S);
    end Last_Status;

    procedure Put(Error : TWI.Error_Code) is
    begin
        case Error is
        when TWI.No_Error =>
            Put_Line("No_Error.");
        when TWI.Busy =>
            Put_Line("Busy");
        when TWI.Invalid =>
            Put_Line("Invalid");
        when TWI.Capacity =>
            Put_Line("Capacity");
        when TWI.Invalid_Buffer =>
            Put_Line("Invalid_Buffer");
        when TWI.Bad_State =>
            Put_Line("State.");
        when TWI.SLA_NAK =>
            Put_Line("SLA_NAK");
        when TWI.Failed =>
            Put_Line("Failed");
        end case;        
    end Put;

    procedure Put_Error is
        E : TWI.Error_Code := TWI.Get_Error;
    begin
        Put("Error: ");
        Put(E);
        CRLF;
    end Put_Error;

    My_Buffer :    aliased TWI.Data_Array := (0..31 => 0);

    procedure Test is
        use AVR;
        use TWI;

        Buf_Ptr :   Data_Array_Ptr := My_Buffer'Access;
        Error :     Error_Code;
        Ch :        Character;
    begin

        Put_Line("Test Begins:");

        loop
            Put("Ready: ");
            Ch := UART.Get;
            Put(Ch);
            CRLF;

            case Ch is
            when 'i' =>
                Put_Line("Init..");
                TWI.Initialize(16#01#,0,Buf_Ptr);
                Clear(Error);
                Put(Error);
            when 'a' =>
                declare
                    A : Data_Array := ( IOCON, IOCON_CFG );
                    B : Data_Array := ( IODIR, IODIR_CFG );
                begin
                    TWI.Write(MCP23017,A,Error);
                    Put(Error);
                    TWI.Write(MCP23017,B,Error);
                    Put(Error);
                end;
            when 'x' =>
                Master(Error);
                Put(Error);
                Put_Count;
                Put_Status;
            when others =>
                Put_Line("??");
                Put_Error;
                Put_Count;
                Put_Status;
                Put("Mode: ");
                Put(TWI.Get_Mode);
                CRLF;
                Last_Status;
                X_Status;
            end case;
        end loop;

    end Test;

begin
    -- Polled Input Driver:
    AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);
end Test_IO;
