-- test.adb - Sat Oct 19 18:36:08 2013
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Test package for ADC library
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

----------------------------------------------------------------------
-- NOTES:
--
-- This test program by default runs the ADC in Free Running mode,
-- but not retriggered. Retriggered mode can be tested by changing
-- the value of Auto_Retrigger below.
--
-- By default, the readings are from ADC0. Change Channel to test
-- another analog input.
--
-- By default, the AVcc voltage reference is used. Change variable
-- Ref, to try another.
--
-- LED:
--  1. At startup, it briefly lights to indicate it's alive.
--  2. During the test, it lights if the ADC328 package indicates
--     that ADC conversion values were lost (due to the caller being
--     slow to pick them up).
--  3. LED is expected to be on pin B5.
--
----------------------------------------------------------------------

with Interfaces;    use Interfaces;
with AVR.MCU;
with AVR.UART;
with AVR.Strings;   use AVR.Strings;
with AVR.Int_Img;

with ADC328;

package body Test is

    DD_LED :    Boolean     renames AVR.MCU.DDRB_Bits(AVR.MCU.DDB5_Bit);
    BV_LED :    Boolean     renames AVR.MCU.PORTB_Bits(AVR.MCU.PORTB5_Bit);

    procedure CRLF is
    begin
        AVR.UART.Put(Character'Val(16#0D#));
        AVR.UART.Put(Character'Val(16#0A#));
    end CRLF;

    procedure Put(S : AVR_String) is
    begin
        for X in S'Range loop
            AVR.UART.Put(S(X));
        end loop;
    end Put;

    procedure Put_Line(S : AVR_String) is
    begin
        for X in S'Range loop
            AVR.UART.Put(S(X));
        end loop;
        AVR.UART.CRLF;
    end Put_Line;    

    procedure Put_Word(Word : Unsigned_16) is
        use AVR.Int_Img;
        Img : AStr5;
    begin
        U16_Img_Right(Word,Img);
        Put(Img);
    end Put_Word;

    procedure Run is
        use ADC328;

        Ready :             Boolean;            -- True when we have data
        Value :             Unsigned_16;        -- Last fetched ADC value
        Missed :            Boolean := false;   -- True if we lost ADC values
        Channel :           ADC_Channel := ADC0;
        Ref :               ADC_Ref := AVcc;    -- Voltage reference
        Mode_10_Bits :      Boolean := true;    -- 10 / 8 bit modes
        Auto_Retrigger :    Boolean := false;   -- Retrigger / Free running
    begin

        DD_LED := AVR.DD_Output;
        BV_LED := true;                         -- Momentary light at initialization

        AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);
        Put_Line("Test Begins:");

        Select_Prescaler(Divide_By_128);
        Select_Channel(Channel);
        Select_Trigger(Free_Running);
        Select_Reference(Ref);
        if Auto_Retrigger then
            Enable_Trigger(true);
        end if;

        Start(Mode_10_Bits);
        BV_LED := false;

        loop
            Read(Value,Ready);
            if Ready then
                Lost(Missed);
                BV_LED := Missed;
                if Auto_Retrigger then
                    Put("Auto: ");
                else
                    Put("Free: ");
                end if;
                Put_Word(Value);
                CRLF;
                if not Auto_Retrigger then
                    Start(Mode_10_Bits);
                end if;
            end if;
        end loop;
    end Run;

end Test;

-- End test.adb
