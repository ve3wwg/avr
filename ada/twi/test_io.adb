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

    procedure Put_Bool(F : Boolean) is
    begin
        if F then
            Put_Line("T");
        else
            Put_Line("F");
        end if;
    end Put_Bool;

--    procedure Put(Error : TWI.Error_Code) is
--    begin
--        case Error is
--        when TWI.No_Error =>
--            Put_Line("No_Error.");
--        when TWI.Busy =>
--            Put_Line("Busy");
--        when TWI.Invalid =>
--            Put_Line("Invalid");
--        when TWI.SLA_NAK =>
--            Put_Line("SLA_NAK");
--        when TWI.Bus_Error =>
--            Put_Line("Bus_Error");
--        when TWI.Failed =>
--            Put_Line("Failed");
--        end case;        
--    end Put;

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

    Count :             Unsigned_8 := 0;

    procedure My_Idle is
    begin
        Count := Count + 1;
    end My_Idle;

    Do_Exit : Boolean := false;
    My_Data : TWI.Data_Array := ( 10, 11, 12, 13 );
    My_Reg :  Unsigned_16    := My_Data'First;

    procedure My_Transmitter(Count : Natural; Byte : out Unsigned_8; Ack : in out Boolean) is
    begin

        if My_Reg > My_Data'Last then
            My_Reg := My_Data'First;
        end if;
        Byte := My_Data(My_Reg);
        My_Reg := My_Reg + 1;

    end My_Transmitter;

    procedure My_Receiver(Count : Natural; Gen_Call : Boolean; Byte : Unsigned_8; Ack : in out Boolean) is
    begin

        if Count = 0 then
            My_Reg := Unsigned_16(Byte);
        else
            My_Data(My_Reg) := Byte;
            My_Reg := My_Reg + 1;
            if My_Reg > My_Data'Last then
                My_Reg := My_Data'First;
            end if;
        end if;

    end My_Receiver;

    procedure My_EOT(Count : Natural; Receiving : Boolean; Exit_Req : in out Boolean) is
    begin
        null;
    end My_EOT;

    procedure Test is
        use AVR, AVR.Strings;
        use TWI;

        Test_Begins :   constant PStr := "Test Begins:";
    begin

        AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);

        Put_Pstr("Test Begins:");
        CRLF;
        CRLF;

        TWI.Set_Idle_Proc(My_Idle'Access);
        TWI.Initialize(16#40#,0);

        Put_Line("Starting slave mode..");
        TWI.Slave(My_Receiver'Access,My_Transmitter'Access,My_EOT'Access);
        XStatus;

        loop
            null;
        end loop;

    end Test;

end Test_IO;
