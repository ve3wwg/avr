-- adc328.adb - Tue Oct 15 21:48:23 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.MCU;
-- with AVR.Wait;

package body ADC328 is

    ADCSRA :    Unsigned_8  renames AVR.MCU.ADCSRA;

    BV_ADEN :   Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADEN_Bit);
    BV_ADSC :   Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADSC_Bit);
    BV_ADATE :  Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADATE_Bit);
    BV_ADIF :   Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADIF_Bit);
    BV_ADIE :   Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADIE_Bit);

    ADCL :      Unsigned_8  renames AVR.MCU.ADCL;
    ADCH :      Unsigned_8  renames AVR.MCU.ADCH;

    ADCSRB :    Unsigned_8  renames AVR.MCU.ADCSRB;

    BV_ADME :   Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ACME_Bit);

    DIDR0 :     Unsigned_8  renames AVR.MCU.DIDR0;

    BV_ADC5D :  Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADC5D_Bit);
    BV_ADC4D :  Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADC4D_Bit);
    BV_ADC3D :  Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADC3D_Bit);
    BV_ADC2D :  Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADC2D_Bit);
    BV_ADC1D :  Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADC1D_Bit);
    BV_ADC0D :  Boolean     renames AVR.MCU.ADCSRA_Bits(AVR.MCU.ADC0D_Bit);


    procedure Set_Prescaler(Prescale : Prescale_Type) is
        use Interfaces;
        P : Unsigned_8 := Unsigned_8(Prescale);
        A : Unsigned_8 := ADCSRA and 2#1111_1000#;
    begin

        ADCSRA := A or (P and 2#0000_0111#);

    end Set_Prescaler;

    procedure Set_Trigger(Trig_Source : Auto_Trigger) is
        B : Unsigned_8 := ADCSRB and 2#1111_1000#;
        T : Unsigned_8 := Unsigned_8(Auto_Trigger'Pos(Trig_Source));
    begin
        
        ADCSRB := B or T;

    end Set_Trigger;

    procedure Enable_Trigger(On : Boolean) is
    begin

        if On then
            BV_ADATE := true;   -- Auto triggering on
        else
            BV_ADATE := false;
        end if;

    end Enable_Trigger;


    procedure ISR;
    pragma Machine_Attribute(
        Entity => ISR,
        Attribute_Name => "signal"
    );
    pragma Export(C,ISR,AVR.MCU.Sig_TWI_String);

    procedure ISR is
    begin
    
        null;

    end ISR;

end ADC328;
