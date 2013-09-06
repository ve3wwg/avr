-- testio.adb - Thu Sep  5 22:41:48 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- IO Support for TestMain.adb
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.ATmega168;

package body Test_IO is

    procedure Pin_IO(Pin : PCD8544.IO_Pin; State : Boolean) is
        use AVR, AVR.ATmega168, PCD8544;

        -- Bits used in Port D
        Bit_CE :        constant := 4;
        Bit_Reset :     constant := 3;
        Bit_DC :        constant := 2;
        Bit_SDIN :      constant := 1;
        Bit_SCLK :      constant := 0;

        -- Data Direction (port D)
        DD_CE :         Boolean renames DDRD_Bits(Bit_CE);
        DD_RESET :      Boolean renames DDRD_Bits(Bit_Reset);
        DD_DC :         Boolean renames DDRD_Bits(Bit_DC);
        DD_SDIN :       Boolean renames DDRD_Bits(Bit_SDIN);
        DD_SCLK :       Boolean renames DDRD_Bits(Bit_SCLK);

        -- Bit Values (Port D)
        BV_CE :         Boolean renames PORTD_Bits(Bit_CE);
        BV_Reset :      Boolean renames PORTD_Bits(Bit_Reset);
        BV_DC :         Boolean renames PORTD_Bits(Bit_DC);
        BV_SDIN :       Boolean renames PORTD_Bits(Bit_SDIN);
        BV_SCLK :       Boolean renames PORTD_Bits(Bit_SCLK);

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

end Test_IO;
