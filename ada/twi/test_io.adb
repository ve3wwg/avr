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


    MCP23017 :  constant TWI.Slave_Addr   := 16#20#;

    IODIRA :    constant Unsigned_8 := 16#00#;
    IODIRB :    constant Unsigned_8 := 16#01#;
    IOCON :     constant Unsigned_8 := 16#0A#;

    IOCON_CFG : constant Unsigned_8 := 2#0000_0000#;
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

    procedure Put_Byte(U : Unsigned_8) is
        S : AVR_String(1..2);
    begin
        To_Hex(U,S);
        Put(S);
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

--    procedure Put_Error is
--        E : TWI.Error_Code := TWI.Get_Error;
--    begin
--        Put("Error: ");
--        Put(E);
--        CRLF;
--    end Put_Error;

    My_Buffer :     aliased TWI.Data_Array := (
                        IOCON,  IOCON_CFG,      -- 0..1     Set Register Config (/SEQOP)
                        IODIRA, 16#C3#,         -- 2..3     Set I/O Config
                        0,                      -- 4..4     Read IODIRA
                        IODIRA, 16#AA#, 16#33#, -- 5..7     IODIRA = AA, B=33
                        IODIRB,                 -- 8..8
                        IODIRA, 16#12#, 16#34#, -- 9..11
                        0 );

    Xfer_0 :        aliased TWI.Xfer_Array := (
                        0 => ( Addr => MCP23017, Xfer => TWI.Write, First => 0, Last => 1 )
                    );

    Xfer_1 :        aliased TWI.Xfer_Array := (
                        ( Addr => MCP23017, Xfer => TWI.Write, First => 9, Last => 11 ),
                        ( Addr => MCP23017, Xfer => TWI.Write, First => 2, Last => 2 ),
                        ( Addr => MCP23017, Xfer => TWI.Read,  First => 4, Last => 4 )
                    );

    Xfer_2 :        aliased TWI.Xfer_Array := (
                        ( Addr => MCP23017, Xfer => TWI.Write, First => 2, Last => 2 ),
                        ( Addr => MCP23017, Xfer => TWI.Read,  First => 4, Last => 4 )
                    );

    Xfer_3 :        aliased TWI.Xfer_Array := (
                        0 => ( Addr => MCP23017, Xfer => TWI.Write, First => 5, Last => 7 )
                    );

    Xfer_4 :        aliased TWI.Xfer_Array := (
                        ( Addr => MCP23017, Xfer => TWI.Write, First => 8, Last => 8 ),
                        ( Addr => MCP23017, Xfer => TWI.Read,  First => 4, Last => 4 )
                    );

    procedure Test is
        use AVR, AVR.Strings;
        use TWI;

        Test_Begins :   constant PStr := "Test Begins: ";
        Ready :         constant PStr := "Ready: ";
        Init_Msg :      constant PStr := "Init..";
        Mode_Msg :      constant PStr := "Mode: ";

        Error :         Error_Code;
        Ch :            Character;
    begin

        AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);

        Put_Pstr(Test_Begins);
        CRLF;
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
                TWI.Initialize(16#01#,0);

            when '0' =>
                TWI.Master(Xfer_0'Access,My_Buffer'Access,Error);

            when '1' =>
                TWI.Master(Xfer_1'Access,My_Buffer'Access,Error);
                if Error /= No_Error then
                    Put_Line("Er!");
                    Put(Error);
                    CRLF;
                end if;

            when '2' =>
                TWI.Master(Xfer_2'Access,My_Buffer'Access,Error);
                if Error /= No_Error then
                    Put_Line("Er!");
                    Put(Error);
                    CRLF;
                end if;

            when '3' =>
                TWI.Master(Xfer_3'Access,My_Buffer'Access,Error);
                TWI.Complete(Error);
                Put(Error);
                CRLF;

            when '4' =>
                TWI.Master(Xfer_4'Access,My_Buffer'Access,Error);

            when 'r' =>
                TWI.Reset;
                Put_Line("Reset");

            when 'v' =>
                Put_Byte(My_Buffer(4));
                CRLF;

            when ' ' =>
                CRLF;

            when others =>
--                Put_PStr(Mode_Msg);
--                Put(TWI.Get_Mode);
--                CRLF;
                XStatus;
            end case;
        end loop;

    end Test;

end Test_IO;
