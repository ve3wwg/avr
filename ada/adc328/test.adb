-- test.adb - Sat Oct 19 18:36:08 2013
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Test package for ADC library
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;    use Interfaces;
with AVR.UART;
with AVR.Strings;   use AVR.Strings;
with AVR.Int_Img;

with ADC328;

package body Test is

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

        type Nat is range 0..1000000;

        Ready : Boolean;
        Value : Unsigned_16;
        Dots :  Boolean := false;
    begin

        AVR.UART.Init(AVR.UART.Baud_19200_16MHz,False);
        Put_Line("Test Begins:");

        Select_Prescaler(Divide_By_128);
        Select_Channel(ADC0);
        Select_Trigger(Free_Running);
        Select_Reference(AVcc);
        Start;

        loop
            Read(Value,Ready);
            if Ready then
                if Dots then
                    CRLF;
                    Dots := false;
                end if;
                Put_Word(Value);
                Start;
            else
                if not Dots then
                    Put_Line("Waiting..");
                    Dots := true;
                end if;
            end if;
        end loop;
    end Run;

end Test;

-- End test.adb
