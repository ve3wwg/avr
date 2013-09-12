-- testio.adb - Thu Sep  5 22:41:48 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- IO Support for TestMain.adb
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.MCU;
with AVR.Wait;
with TWI;
with PCD8544;

package body Test_IO is

    -- Bits used in Port D
    Bit_CE :        constant := 0;  -- Port B

    Bit_Reset :     constant := 3;  -- Port D
    Bit_DC :        constant := 2;  -- Port D
    Bit_SDIN :      constant := 6;  -- Port D
    Bit_SCLK :      constant := 7;  -- Port D

    -- Data Direction (port D)
    DD_CE :         Boolean renames AVR.MCU.DDRB_Bits(Bit_CE);
    DD_RESET :      Boolean renames AVR.MCU.DDRD_Bits(Bit_Reset);
    DD_DC :         Boolean renames AVR.MCU.DDRD_Bits(Bit_DC);
    DD_SDIN :       Boolean renames AVR.MCU.DDRD_Bits(Bit_SDIN);
    DD_SCLK :       Boolean renames AVR.MCU.DDRD_Bits(Bit_SCLK);

    -- Bit Values (Port D)
    BV_CE :         Boolean renames AVR.MCU.PORTB_Bits(Bit_CE);
    BV_Reset :      Boolean renames AVR.MCU.PORTD_Bits(Bit_Reset);
    BV_DC :         Boolean renames AVR.MCU.PORTD_Bits(Bit_DC);
    BV_SDIN :       Boolean renames AVR.MCU.PORTD_Bits(Bit_SDIN);
    BV_SCLK :       Boolean renames AVR.MCU.PORTD_Bits(Bit_SCLK);

    procedure Pin_IO(Pin : PCD8544.IO_Pin; State : Boolean) is
        use PCD8544, AVR;
    begin

        case Pin is
            when Configure =>
                BV_CE    := High;
                BV_RESET := High;
                BV_DC    := High;
                BV_SDIN  := High;
                BV_SCLK  := Low;

                DD_CE    := DD_Output;
                DD_RESET := DD_Output;
                DD_DC    := DD_Output;
                DD_SDIN  := DD_Output;
                DD_SCLK  := DD_Output;
            when CE =>
                BV_CE    := State;
            when Reset =>
                BV_RESET := State;
            when DataCmd =>
                BV_DC    := State;
            when DataIn =>
                BV_SDIN  := State;
            when Clock =>
                BV_SCLK  := State;
        end case;

    end Pin_IO;

    procedure Blinky is
        use AVR;
        procedure Delay_MS(MS : Natural) is
        begin
            for X in 1..MS loop
                AVR.Wait.Wait_4_Cycles(8000);
            end loop;
        end;

        LED : Boolean renames MCU.PortB_Bits(5);
    begin

        MCU.DDRB_Bits := (others => DD_Output); 

--        loop
        LED := True;
        Delay_MS(600);
        LED := False;
        Delay_MS(200);
--        end loop;

    end Blinky;


--    Buffer :    aliased TWI.Data_Array := ( 0, 1, 2 );
--    I2C_Msg :   aliased TWI.Msg_Array := (
--                0 => (
--                    Addr => 16#23#,
--                    Buffer => Test_IO.Buffer'Access,
--                    Write => True
--                )
--        );

    procedure Test is
        use PCD8544, TWI;

        Context :   IO_Context;
        Msg :       Data_Array := (0, 1, 2, 4, 5);
        Error :     Error_Code;
    begin

        Initialize(Context,Test_IO.Pin_IO'Access);
        Put_Line(Context,"Ready.");

        TWI.Initialize(16#01#,0);
        Put_Line(Context,"Init.");

        TWI.Clear(Error);
        TWI.Request(16#05#,3,True,Error);
        TWI.Request(16#05#,2,False,Error);
        TWI.Transfer(Msg,Error);

--        case Error is
--        when No_Error =>
--            Put_Line(Context,"No_Error.");
--        when TWI.Buffer =>
--            Put_Line(Context,"Buffer");
--        when Busy =>
--            Put_Line(Context,"Busy");
--        when Bad_State =>
--            Put_Line(Context,"State.");
--        end case;        

        loop
            Test_IO.Blinky;
        end loop;

    end Test;

end Test_IO;
