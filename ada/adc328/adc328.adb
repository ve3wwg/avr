-- adc328.adb - Tue Oct 15 21:48:23 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.MCU;
-- with AVR.Wait;

package body ADC328 is

    DD_Input :  Boolean     renames AVR.DD_Input;
    DD_Output : Boolean     renames AVR.DD_Output;

    PORTC :     Unsigned_8  renames AVR.MCU.PORTC;

    DD_C5 :     Boolean     renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC5_Bit);
    DD_C4 :     Boolean     renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC4_Bit);
    DD_C3 :     Boolean     renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC3_Bit);
    DD_C2 :     Boolean     renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC2_Bit);
    DD_C1 :     Boolean     renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC1_Bit);
    DD_C0 :     Boolean     renames AVR.MCU.DDRC_Bits(AVR.MCU.DDC0_Bit);

    BV_C5 :     Boolean     renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC5_Bit);
    BV_C4 :     Boolean     renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC4_Bit);
    BV_C3 :     Boolean     renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC3_Bit);
    BV_C2 :     Boolean     renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC2_Bit);
    BV_C1 :     Boolean     renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC1_Bit);
    BV_C0 :     Boolean     renames AVR.MCU.PORTC_Bits(AVR.MCU.PORTC0_Bit);

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
    -- ADC Buffer
    ------------------------------------------------------------------

    type Word_Array is array (Unsigned_8 range <>) of Unsigned_16;

    Buffer :    Word_Array(0..4) := ( 0, others => 0 );
    Buf_X :     Unsigned_8 := 0;        -- Index to last written value
    ADC_X :     Unsigned_8 := 0;        -- Tail pointer, behind last written value
    Missed :    Boolean := false;       -- Set true if we lost ADC values

    pragma volatile(Buf_X);
    pragma volatile(ADC_X);
    pragma volatile(Missed);

    ------------------------------------------------------------------
    -- Set the ADC Clock Prescaler
    ------------------------------------------------------------------

    procedure Set_Prescaler(Prescale : Prescale_Type) is
        use Interfaces;
        P : Unsigned_8 := Unsigned_8(Prescale);
        A : Unsigned_8 := ADCSRA and 2#1111_1000#;
    begin

        BV_ADEN := true;    -- Enable ADC
        BV_ADIE := false;   -- Disable interrupts for now

        ADCSRA := A or (P and 2#0000_0111#);

    end Set_Prescaler;

    ------------------------------------------------------------------
    -- Choose the Auto Retrigger Source
    ------------------------------------------------------------------

    procedure Set_Trigger(Trig_Source : Auto_Trigger) is
        B : Unsigned_8 := ADCSRB and 2#1111_1000#;
        T : Unsigned_8 := Unsigned_8(Auto_Trigger'Pos(Trig_Source));
    begin
        
        BV_ADEN := true;    -- Enable ADC
        BV_ADIE := false;   -- Disable interrupts for now

        ADCSRB := B or T;

    end Set_Trigger;

    ------------------------------------------------------------------
    -- Enable / Disable the Auto Trigger
    ------------------------------------------------------------------

    procedure Enable_Trigger(On : Boolean) is
    begin

        BV_ADEN := true;        -- Enable ADC
        BV_ADIE := false;       -- Disable interrupts for now

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

        BV_ADEN := true;        -- Enable ADC
        BV_ADIE := false;       -- Disable interrupts for now

        case Ch is
            when ADC0 =>
                DD_C0    := DD_Input;
                BV_ADC0D := true;   -- Disable digital input
            when ADC1 =>
                DD_C1    := DD_Input;
                BV_ADC1D := true;   -- Disable digital input
            when ADC2 =>
                DD_C2    := DD_Input;
                BV_ADC2D := true;   -- Disable digital input
            when ADC3 =>
                DD_C3    := DD_Input;
                BV_ADC3D := true;   -- Disable digital input
            when ADC4 =>
                DD_C4    := DD_Input;
                BV_ADC4D := true;   -- Disable digital input
            when ADC5 =>
                DD_C5    := DD_Input;
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
        
        BV_ADEN := true;        -- Enable ADC
        BV_ADIE := false;       -- Disable interrupts for now

        ADMUX := M or Shift_Left(Unsigned_8(ADC_Ref'Pos(Ref)),6);

    end Select_Reference;

    ------------------------------------------------------------------
    -- Enable the device and interrupts
    ------------------------------------------------------------------

    procedure Enable_Interrupts(On : Boolean) is
    begin

        BV_ADEN := true;        -- Enable ADC
        BV_ADIE := true;        -- Enable interrupts

    end Enable_Interrupts;

    ------------------------------------------------------------------
    -- Start the [first] Conversion
    ------------------------------------------------------------------

    procedure Start is
    begin

        Buf_X := Buffer'First;
        ADC_X := Buffer'First;
        Missed := false;

        BV_ADEN := true;        -- Enable ADC
        BV_ADIE := true;        -- Enable interrupts
        BV_ADSC := true;

    end Start;


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
    
        Buf_X := Buf_X + 1;
        if Buf_X > Buffer'Last then
            Buf_X := Buffer'First;
        end if;

        if Buf_X /= ADC_X then
            Buffer(Buf_X) := Shift_Left(Unsigned_16(ADCH and 2#0000_0011#),8) or Unsigned_16(ADCL);
        else
            Missed := true;
        end if;

    end ISR;

end ADC328;
