with AVR.MCU;
with AVR.Wait;

use AVR;

procedure Blinky is
    procedure Delay_MS(MS : Natural) is
    begin
        for X in 1..MS loop
            AVR.Wait.Wait_4_Cycles(8000);
        end loop;
    end;

    LED : Boolean renames MCU.PortB_Bits(5);
begin

    MCU.DDRB_Bits := (others => DD_Output); 

    loop
        LED := True;
        Delay_MS(600);
        LED := False;
        Delay_MS(200);
    end loop;

end Blinky;
