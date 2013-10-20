-- adc328.adb - Tue Oct 15 21:48:23 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.MCU;
with AVR.Interrupts;

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
    -- ADC Buffer and Values
    ------------------------------------------------------------------

    type Mod4_Type is mod 4;
    type Word_Array is array (Mod4_Type) of Unsigned_16;

    Mode_10 :   Boolean := true;        -- True if reading 10-bit samples, else 8-bit
    Buffer :    Word_Array := ( 0, others => 0 );
    Buf_X :     Mod4_Type := 0;         -- Index to last written value
    ADC_X :     Mod4_Type := 0;         -- Tail pointer, behind last written value
    Missed :    Boolean := false;       -- Set true if we lost ADC values

    pragma volatile(Mode_10);
    pragma volatile(Buffer);
    pragma volatile(Buf_X);
    pragma volatile(ADC_X);
    pragma volatile(Missed);

    ------------------------------------------------------------------
    -- Set the ADC Clock Prescaler
    ------------------------------------------------------------------

    procedure Select_Prescaler(Prescale : Prescale_Type) is
        use Interfaces;
        P : Unsigned_8 := Unsigned_8(Prescale_Type'Pos(Prescale));
        A : Unsigned_8 := ADCSRA and 2#1111_1000#;
    begin

        BV_ADEN := true;    -- Enable ADC
        BV_ADIE := false;   -- Disable interrupts for now

        ADCSRA := A or (P and 2#0000_0111#);

    end Select_Prescaler;

    ------------------------------------------------------------------
    -- Choose the Auto Retrigger Source
    ------------------------------------------------------------------

    procedure Select_Trigger(Trig_Source : Auto_Trigger) is
        B : Unsigned_8 := ADCSRB and 2#1111_1000#;
        T : Unsigned_8 := Unsigned_8(Auto_Trigger'Pos(Trig_Source));
    begin
        
        BV_ADEN := true;    -- Enable ADC
        BV_ADIE := false;   -- Disable interrupts for now

        ADCSRB := B or T;

    end Select_Trigger;

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
    -- Start the [first] Conversion
    ------------------------------------------------------------------

    procedure Start(Bits_10 : boolean := true) is
    begin

        BV_ADEN := true;        -- Enable ADC

        Buf_X := Buffer'First;
        ADC_X := Buffer'First;
        Missed := false;

        Mode_10 := Bits_10;

        if Bits_10 then
            BV_ADLAR := false;  -- ADCH contains upper MSB 2 bits + 8 LSB in ADCL
        else
            BV_ADLAR := true;   -- ADCH contains full MSB 8 bits
        end if;

        AVR.Interrupts.Disable;

        BV_ADIF := true;        -- Clear any pre-existing interrupt
        BV_ADIE := true;        -- Enable interrupts
        BV_ADSC := true;

        AVR.Interrupts.Enable;

    end Start;

    ------------------------------------------------------------------
    -- Unblocking Read of ADC Value
    ------------------------------------------------------------------

    procedure Read(Value : out Unsigned_16; Ready : out Boolean) is
    begin

        Ready := Buf_X /= ADC_X;

        if Ready then
            ADC_X := ADC_X + 1;
            Value := Buffer(ADC_X);
        end if;

    end Read;

    ------------------------------------------------------------------
    -- Block until a Value is Ready to be Returned
    ------------------------------------------------------------------

    procedure Read(Value : out Unsigned_16; Idle : Idle_Proc) is
    begin

        while Buf_X = ADC_X loop
            Idle.all;
        end loop;
        
        ADC_X := ADC_X + 1;
        Value := Buffer(ADC_X);

    end Read;

    ------------------------------------------------------------------
    -- Return true if there were lost values
    ------------------------------------------------------------------

    procedure Lost(Indicator : out Boolean) is
    begin
        Indicator := Missed;    -- Return indicator
        Missed    := false;     -- Reset indicator
    end Lost;

    ------------------------------------------------------------------
    -- ADC Interrupt Handler
    ------------------------------------------------------------------

    procedure ISR;
    pragma Machine_Attribute(
        Entity         => ISR,
        Attribute_Name => "signal"
    );

    pragma Export(C,ISR,AVR.MCU.Sig_ADC_String);

    procedure ISR is
        L, H : Unsigned_8;
    begin
    
        if Buf_X + 1 /= ADC_X then
            Buf_X := Buf_X + 1;
            if Mode_10 then
                L := ADCL;
                H := ADCH and 2#0000_0011#;
                Buffer(Buf_X) := Shift_Left(Unsigned_16(H),8) or Unsigned_16(L);
            else
                Buffer(Buf_X) := Unsigned_16(ADCH);
            end if;
        else
            Missed := true;
        end if;

    end ISR;

end ADC328;
