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
with MCP23017;

package body Test_IO is

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

    procedure Put_Byte(U : Unsigned_8) is
        S : AVR_String(1..2);
    begin
        Put("Byte: ");
        To_Hex(U,S);
        Put(S);
        CRLF;
    end Put_Byte;

    procedure Put(Error : TWI.Error_Code) is
    begin
        case Error is
        when TWI.No_Error =>
            Put_Line("No_Error.");
        when TWI.Busy =>
            Put_Line("Busy");
        when TWI.Invalid =>
            Put_Line("Invalid");
        when TWI.SLA_NAK =>
            Put_Line("SLA_NAK");
        when TWI.Bus_Error =>
            Put_Line("Bus_Error");
        when TWI.Failed =>
            Put_Line("Failed");
        end case;        
    end Put;

    procedure XStatus is
        S : AVR_String(1..2);
        Z : TWI.Data_Array(0..63);
        SX : Unsigned_16;
    begin

        TWI.Get_Status(Z,SX);

        for X in Z'Range loop
            exit when X > SX;

            To_Hex(Z(X),S);
            Put(S);
            Put(' ');
        end loop;

        Put(';');
        CRLF;

    end XStatus;

    procedure Put_Error(E : MCP23017.Error_Code) is
        use MCP23017;
    begin
        if E = No_Error then
            Put_Line("No_Error");
        else
            Put_Line("Failed.");
        end if;
    end Put_Error;

    A_MCP23017 : constant := 16#20#;

    procedure Test is
        use AVR, AVR.Strings;
        use TWI;

        Test_Begins :   constant PStr := "Test Begins: ";
        Ready :         constant PStr := "Ready: ";
        Init_Msg :      constant PStr := "Init..";
        Mode_Msg :      constant PStr := "Mode: ";

        Error :         MCP23017.Error_Code;
        Ch :            Character;
        A, B :          Unsigned_8 := 0;
    begin

        AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);

        Put_Pstr(Test_Begins);
        CRLF;
        CRLF;

        TWI.Initialize(16#01#,0);

        MCP23017.Initialize(A_MCP23017,Error);
        Put_Error(Error);

        MCP23017.Set_Direction(A_MCP23017,MCP23017.DD_Outputs,MCP23017.DD_Outputs,Error);
        Put_Error(Error);

        loop
            Put_Pstr(Ready);
            Ch := UART.Get;
            Put(Ch);
            CRLF;

            case Ch is
            when '0' =>
                MCP23017.Write(A_MCP23017,16#00#,16#00#,Error);
                Put_Error(Error);

            when '1' =>
                MCP23017.Write(A_MCP23017,16#FF#,16#FF#,Error);
                Put_Error(Error);

            when '2' =>
                A := A xor 16#FF#;
                MCP23017.Write(A_MCP23017,MCP23017.Port_A,A,Error);
                Put_Error(Error);

            when '3' =>
                B := B xor 16#FF#;
                MCP23017.Write(A_MCP23017,MCP23017.Port_B,B,Error);
                Put_Error(Error);

            when 'a' =>
                MCP23017.Read(A_MCP23017,MCP23017.Port_A,A,Error);
                Put_Error(Error);
                Put_Byte(A);

            when 'b' =>
                MCP23017.Read(A_MCP23017,MCP23017.Port_B,B,Error);
                Put_Error(Error);
                Put_Byte(B);

            when 'p' =>
                MCP23017.Get_Polarity(A_MCP23017,A,B,Error);
                Put_Byte(A);
                Put_Byte(B);

            when 'P' =>
                MCP23017.Set_Polarity(A_MCP23017,A,B,Error);
                Put_Byte(A);
                Put_Byte(B);

            when '=' =>
                Put_Byte(A);
                Put_Byte(B);

            when 'r' =>
                MCP23017.Read(A_MCP23017,A,B,Error);
                Put_Byte(A);
                Put_Byte(B);

            when 'I' =>
                declare
                    E, V, C : Nat8 := 0;
                begin
                    MCP23017.Get_Int_Change(A_MCP23017,MCP23017.Port_A,E,V,C,Error);
                    Put_Error(Error);
                    Put_Byte(E);
                    Put_Byte(V);
                    Put_Byte(C);
                end;

            when 'J' =>
                declare
                    E :     Nat8 := 16#FF#;
                    V :     Nat8 := 16#FF#;
                    C :     Nat8 := 16#5A#;
                begin
                    MCP23017.Set_Int_Change(A_MCP23017,MCP23017.Port_A,E,V,C,Error);
                    Put_Error(Error);
                    MCP23017.Get_Int_Change(A_MCP23017,MCP23017.Port_A,E,V,C,Error);
                    Put_Error(Error);
                    Put_Byte(E);
                    Put_Byte(V);
                    Put_Byte(C);
                end;

            when 'K' =>
                declare
                    E :     Nat8 := 0;
                    V :     Nat8 := 16#22#;
                    C :     Nat8 := 0;
                begin
                    MCP23017.Set_Int_Change(A_MCP23017,MCP23017.Port_A,E,V,C,Error);
                    Put_Error(Error);
                    MCP23017.Get_Int_Change(A_MCP23017,MCP23017.Port_A,E,V,C,Error);
                    Put_Error(Error);
                    Put_Byte(E);
                    Put_Byte(V);
                    Put_Byte(C);
                end;

            when others =>
                XStatus;
            end case;
        end loop;

    end Test;

end Test_IO;
