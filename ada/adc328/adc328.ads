-- adc328.ads - Tue Oct 15 21:48:42 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.Strings;
with Interfaces;
use Interfaces;

package ADC328 is

    type Error_Code is (
        No_Error,           -- No error (Success)
        Failed              -- Failed for an unknown reason
    );

    type ADC_Channel is (
        ADC0, ADC1, ADC2, ADC3, ADC4, ADC5, ADC6, ADC7,
        ADC_Temp,           -- Temp sensor
        ADC1_1V,            -- 1.1 volt reference
        ADC_0V              -- Gnd 
    );

    type ADC_Ref is (
        Aref,               -- AREF, Internal Vref disabled
        AVcc,               -- AVcc with external capacitor at AREF pin
        ArefInternal        -- Internal 1.1V voltage reference, externap cap at AREF pin
    );

    type Auto_Trigger is (
        Free_Running,       -- Free Running mode
        Comparator,         -- Analog Comparator
        Ext_Int_0,          -- External Interrupt Request 0
        TC0_Match_A,        -- Timer/Counter 0 Compare Match A
        TC0_Overflow,       -- Timer/Counter 0 Overflow
        TC1_Match_B,        -- Timer/Counter 1 Compare Match B
        TC1_Overflow,       -- Timer/Counter 1 Overflow
        TC1_Capture         -- Timer/Counter 1 Capture Event
    );

    ------------------------------------------------------------------
    -- Establish the Prescaler. The CPU clock is divided by this
    -- value. E.g. 16 Mhz CPU clock divided by 128 => 125 kHz
    -- Prescale 1 => 2 .. 7 = 128 (0 == 2 also?)
    ------------------------------------------------------------------

    type Prescale_Type is range 0..7;

    procedure Set_Prescaler(Prescale : Prescale_Type);

    ------------------------------------------------------------------
    -- Select the Analog Input Channel
    ------------------------------------------------------------------

    procedure Select_Channel(Ch : ADC_Channel);

    ------------------------------------------------------------------
    -- Select the ADC Reference Source
    ------------------------------------------------------------------

    procedure Select_Reference(Ref : ADC_Ref);

    ------------------------------------------------------------------
    -- Choose Auto Trigger Source (if enabling auto triggering)
    ------------------------------------------------------------------

    procedure Set_Trigger(Trig_Source : Auto_Trigger);
    procedure Enable_Trigger(On : Boolean);

    ------------------------------------------------------------------
    -- Enable Interrupts
    ------------------------------------------------------------------

    procedure Enable_Interrupts(On : Boolean);
    procedure Start;

    ------------------------------------------------------------------
    -- Representation
    ------------------------------------------------------------------

    for ADC_Ref use (
        Aref            => 0,
        AVcc            => 1,
        ArefInternal    => 3
    );

    for Auto_Trigger use (
        Free_Running    => 0,
        Comparator      => 1,
        Ext_Int_0       => 2,
        TC0_Match_A     => 3,
        TC0_Overflow    => 4,
        TC1_Match_B     => 5,
        TC1_Overflow    => 6,
        TC1_Capture     => 7 
    );

end ADC328;
