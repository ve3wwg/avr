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

    IOCON_CFG : constant Unsigned_8 := 2#0010_0000#;
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

    procedure X_Status is
        Buf : AVR_String(1..60);
    begin
        TWI.XStatus(Buf);
        Put_Line(Buf);
    end X_Status;

    procedure Put_Byte(U : Unsigned_8) is
        S : AVR_String(1..2);
    begin
        TWI.To_Hex(U,S);
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

--    procedure Put_Error is
--        E : TWI.Error_Code := TWI.Get_Error;
--    begin
--        Put("Error: ");
--        Put(E);
--        CRLF;
--    end Put_Error;

    My_Buffer :     aliased TWI.Data_Array := (
                        IOCON,  IOCON_CFG,      -- 0..1     Set Register Config (/SEQOP)
                        IODIRA, 16#E5#,         -- 2..3     Set I/O Config
                        IODIRA,                 -- 4..4     Set reg = IODIRA
                        0,                      -- 5..5     Read IODIRA
                        0 );
    My_Xfer :       aliased TWI.Xfer_Array := (
--                        ( Addr => MCP23017, Write => True, First => 0, Last => 1, Count => 0 ),
                        0..0 => ( Addr => MCP23017, Write => True, First => 2, Last => 3, Count => 0 )
--                        ( Addr => MCP23017, Write => True, First => 4, Last => 4, Count => 0 ),
--                        ( Addr => MCP23017, Write => False, First => 5, Last => 5, Count => 0 )
                    );

    My_Xfer2 :      aliased TWI.Xfer_Array := (
                        ( Addr => MCP23017, Write => True, First => 4, Last => 4, Count => 0 ),
                        ( Addr => MCP23017, Write => False, First => 5, Last => 5, Count => 0 )
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

            when 'x' =>
                TWI.Master(My_Xfer'Access,My_Buffer'Access,Error);
                if Error /= No_Error then
                    Put_Line("Er!");
                    Put(Error);
                    CRLF;
                end if;

            when 'y' =>
                TWI.Master(My_Xfer2'Access,My_Buffer'Access,Error);
                if Error /= No_Error then
                    Put_Line("Er!");
                    Put(Error);
                    CRLF;
                end if;

            when 'r' =>
                TWI.Reset;
                Put_Line("Reset");

            when 'v' =>
                Put_Byte(My_Buffer(5));
                CRLF;

            when ' ' =>
                CRLF;

            when others =>
--                Put_PStr(Mode_Msg);
--                Put(TWI.Get_Mode);
--                CRLF;
                X_Status;
            end case;
        end loop;

    end Test;

end Test_IO;
