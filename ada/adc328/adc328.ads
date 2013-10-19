-- adc328.ads - Tue Oct 15 21:48:42 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with AVR.Strings;
with Interfaces;
use Interfaces;

package ADC328 is

    -- Selects the ADC Channel to read

    type ADC_Channel is (
        ADC0, ADC1, ADC2, ADC3, ADC4, ADC5, ADC6, ADC7,
        ADC_Temp,           -- Temp sensor
        ADC1_1V,            -- 1.1 volt reference
        ADC_0V              -- Gnd 
    );

    -- Selects the ADC Reference

    type ADC_Ref is (
        Aref,               -- AREF, Internal Vref disabled
        AVcc,               -- AVcc with external capacitor at AREF pin
        ArefInternal        -- Internal 1.1V voltage reference, externap cap at AREF pin
    );

    -- Selects the Auto trigger mode

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

    type Prescale_Type is (
        Divide_By_2,
        Divide_By_4,
        Divide_By_8,
        Divide_By_16,
        Divide_By_32,
        Divide_By_64,
        Divide_By_128
    );

    procedure Select_Prescaler(Prescale : Prescale_Type);
    procedure Select_Channel(Ch : ADC_Channel);
    procedure Select_Reference(Ref : ADC_Ref);

    procedure Select_Trigger(Trig_Source : Auto_Trigger);
    procedure Enable_Trigger(On : Boolean);

    procedure Start(Bits_10 : boolean := true);

    type Idle_Proc is access procedure;

    procedure Read(Value : out Unsigned_16; Ready : out Boolean);
    procedure Read(Value : out Unsigned_16; Idle : Idle_Proc);

    procedure Lost(Indicator : out Boolean);

    ------------------------------------------------------------------
    -- Representations
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

    for Prescale_Type use (
        Divide_By_2     => 1,
        Divide_By_4     => 2,
        Divide_By_8     => 3,
        Divide_By_16    => 4,
        Divide_By_32    => 5,
        Divide_By_64    => 6,
        Divide_By_128   => 7
    );

    ------------------------------------------------------------------
    -- Examples
    ------------------------------------------------------------------

--  Select_Prescaler(Divide_By_128);
--  Select_Channel(ADC0);
--  procedure Select_Trigger(Free_Running);
--  Select_Reference(AVcc);
--  Start(true);
--
--  declare
--      Ready : Boolean;
--      Value : Unsigned_16;
--  begin
--      loop
--          Read(Value,Ready);
--          if Ready then
--              ...
--          end if;
--      end loop;
--  end;

end ADC328;
