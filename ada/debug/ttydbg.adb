-- ttydbg.adb - Sat Sep 14 10:14:30 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.UART;
with AVR.Strings;

use AVR.Strings;

package body TtyDbg is

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
    procedure Put_Line(S : AVR_String) is
    begin
        for X in S'Range loop
            Put(S(X));
        end loop;
        AVR.UART.CRLF;
    end Put_Line;

    -- Test Main Routine
    procedure Main is
        use AVR;
    begin

        loop
            Put_Line("Hello World!");
            declare
                Ch :    Character := AVR.UART.Get;
            begin
                Put_Line("You entered '" & Ch & "'.");
            end;
        end loop;

    end Main;

begin
    -- Polled Input Driver:
    AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);
end TtyDbg;


