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

    ADMUX :     Unsigned_8  renames AVR.MCU.ADMUX;

    BV_ADLAR :  Boolean     renames AVR.MCU.ADMUX_Bits(AVR.MCU.ADLAR_Bit);

    ------------------------------------------------------------------
    -- Set the ADC Clock Prescaler
    ------------------------------------------------------------------

    procedure Set_Prescaler(Prescale : Prescale_Type) is
        use Interfaces;
        P : Unsigned_8 := Unsigned_8(Prescale);
        A : Unsigned_8 := ADCSRA and 2#1111_1000#;
    begin

        ADCSRA := A or (P and 2#0000_0111#);

    end Set_Prescaler;

    ------------------------------------------------------------------
    -- Choose the Auto Retrigger Source
    ------------------------------------------------------------------

    procedure Set_Trigger(Trig_Source : Auto_Trigger) is
        B : Unsigned_8 := ADCSRB and 2#1111_1000#;
        T : Unsigned_8 := Unsigned_8(Auto_Trigger'Pos(Trig_Source));
    begin
        
        ADCSRB := B or T;

    end Set_Trigger;

    ------------------------------------------------------------------
    -- Enable / Disable the Auto Trigger
    ------------------------------------------------------------------

    procedure Enable_Trigger(On : Boolean) is
    begin

        if On then
            BV_ADATE := true;   -- Auto triggering on
        else
            BV_ADATE := false;
        end if;

    end Enable_Trigger;

    ------------------------------------------------------------------
    -- Select the ADC Input Channel
    ------------------------------------------------------------------

    procedure Select_Channel(Ch : ADC_Channel) is
        M : Unsigned_8 := ADMUX and 2#1110_0000#;
    begin

        case Ch is
            when ADC0 =>
                BV_ADC0D := true;   -- Disable digital input
            when ADC1 =>
                BV_ADC1D := true;   -- Disable digital input
            when ADC2 =>
                BV_ADC2D := true;   -- Disable digital input
            when ADC3 =>
                BV_ADC3D := true;   -- Disable digital input
            when ADC4 =>
                BV_ADC4D := true;   -- Disable digital input
            when ADC5 =>
                BV_ADC5D := true;   -- Disable digital input
            when ADC6 | ADC7 =>
                null;
            when ADC_Temp =>
                null;
            when ADC1_1V =>
                null;
            when ADC_0V =>
                null;
        end case;

        ADMUX := M or Unsigned_8(ADC_Channel'Pos(Ch));

    end Select_Channel;

    ------------------------------------------------------------------
    -- Select the ADC Reference Source
    ------------------------------------------------------------------

    procedure Select_Reference(Ref : ADC_Ref) is
        M : Unsigned_8 := ADMUX and 2#0011_1111#;
    begin
        
        ADMUX := M or Shift_Left(Unsigned_8(ADC_Ref'Pos(Ref)),6);

    end Select_Reference;

    ------------------------------------------------------------------
    -- ADC Interrupt Handler
    ------------------------------------------------------------------

    procedure ISR;
    pragma Machine_Attribute(
        Entity => ISR,
        Attribute_Name => "signal"
    );
    pragma Export(C,ISR,AVR.MCU.Sig_ADC_String);

    procedure ISR is
    begin
    
        null;

    end ISR;

end ADC328;
