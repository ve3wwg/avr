-- synth.adb - Thu Aug 12 18:39:51 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id: synth.adb,v 1.2 2010-08-27 03:31:45 Warren Gray Exp $
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;

with AVR.MCU;
with AVR.UART;
with AVR.SPI;
with MIDI;
with MIDI.Receiver;
with AVR.SPI.Master;
with AVR.Timer2;
with AVR.Threads;
with Counter_Time;

with MCP4922;

use AVR, Counter_Time, AVR.SPI;

----------------------------------------------------------------------
-- Synthesizer Notes :
----------------------------------------------------------------------
-- 
--  (1) After initialization/reset :
--      a)  Omni is on
--      b)  Channel is set to 1
--      c)  Local is on
--      d)  ADSR is on
-- 
--  (2) ADSR Controls
--      a)  Control 102 :   0 = off, /= 0 for ADSR on (default 127)
--      b)  Control 103 :   0..127, # of ticks for attack (default 6)
--      c)  Control 104 :   0..127, # of ticks for decay (default 6)
--      d)  Control 105 :   0..127, relative CV level for sustain (default 64)
--      e)  Control 106 :   0..127, # of ticks for release (default 20)
-- 
--  (3) Local Control:
--      a)  Value 0 :       Local is off
--      b)  Value 1 :       Local is on, omni = off, channel = 1
--      c)  ...
--      d)  Value 15 :      Local is on, omni = off, channel = 15
--      e)  16..127         Local is on
-- 
----------------------------------------------------------------------

package body Synth is

--  CPU_Mhz :           constant := 16;     -- ATmega168 with 16 Mhz Crystal
--  Timer_Prescale :    constant := 256;    -- Timer2 prescaled by 256
    Timer_Compare :     constant := 128;    -- Timer2 compare value of 128 => 2ms ticks

    Receive_Buffer :    aliased Nat8_Array := ( 0, 0, 0, 0, 0, 0, 0 );
    Buffer_Access :     AVR.UART.Buffer_Ptr := Receive_Buffer'Access;

    ------------------------------------------------------------------
    -- Notes Table :
    ------------------------------------------------------------------
    --  NOTE,      Hz,      usec,  MIDI
    ------------------------------------------------------------------
    --  "C0",      16.35,   61162, 12
    --  "C#0/Db0", 17.32,   57737, 13
    --  "D0",      18.35,   54496, 14
    --  "D#0/Eb0", 19.45,   51414, 15
    --  "E0",      20.6,    48544, 16
    --  "F0",      21.83,   45809, 17
    --  "F#0/Gb0", 23.12,   43253, 18
    --  "G0",      24.5,    40816, 19
    --  "G#0/Ab0", 25.96,   38521, 20
    --  "A0",      27.5,    36364, 21
    --  "A#0/Bb0", 29.14,   34317, 22
    --  "B0",      30.87,   32394, 23
    --  "C1",      32.7,    30581, 24
    --  "C#1/Db1", 34.65,   28860, 25
    --  "D1",      36.71,   27241, 26
    --  "D#1/Eb1", 38.89,   25714, 27
    --  "E1",      41.2,    24272, 28
    --  "F1",      43.65,   22910, 29
    --  "F#1/Gb1", 46.25,   21622, 30
    --  "G1",      49,      20408, 31
    --  "G#1/Ab1", 51.91,   19264, 32
    --  "A1",      55,      18182, 33
    --  "A#1/Bb1", 58.27,   17161, 34
    --  "B1",      61.74,   16197, 35
    --  "C2",      65.41,   15288, 36
    --  "C#2/Db2", 69.3,    14430, 37
    --  "D2",      73.42,   13620, 38
    --  "D#2/Eb2", 77.78,   12857, 39
    --  "E2",      82.41,   12134, 40
    --  "F2",      87.31,   11453, 41
    --  "F#2/Gb2", 92.5,    10811, 42
    --  "G2",      98,      10204, 43
    --  "G#2/Ab2", 103.83,  9631,  44
    --  "A2",      110,     9091,  45
    --  "A#2/Bb2", 116.54,  8581,  46
    --  "B2",      123.47,  8099,  47
    --  "C3",      130.81,  7645,  48
    --  "C#3/Db3", 138.59,  7216,  49
    --  "D3",      146.83,  6811,  50
    --  "D#3/Eb3", 155.56,  6428,  51
    --  "E3",      164.81,  6068,  52
    --  "F3",      174.61,  5727,  53
    --  "F#3/Gb3", 185,     5405,  54
    --  "G3",      196,     5102,  55
    --  "G#3/Ab3", 207.65,  4816,  56
    --  "A3",      220,     4545,  57
    --  "A#3/Bb3", 233.08,  4290,  58
    --  "B3",      246.94,  4050,  59
    --  "C4",      261.63,  3822,  60
    --  "C#4/Db4", 277.18,  3608,  61
    --  "D4",      293.66,  3405,  62
    --  "D#4/Eb4", 311.13,  3214,  63
    --  "E4",      329.63,  3034,  64
    --  "F4",      349.23,  2863,  65
    --  "F#4/Gb4", 369.99,  2703,  66
    --  "G4",      392,     2551,  67
    --  "G#4/Ab4", 415.3,   2408,  68
    --  "A4",      440,     2273,  69
    --  "A#4/Bb4", 466.16,  2145,  70
    --  "B4",      493.88,  2025,  71
    --  "C5",      523.25,  1911,  72
    --  "C#5/Db5", 554.37,  1804,  73
    --  "D5",      587.33,  1703,  74
    --  "D#5/Eb5", 622.25,  1607,  75
    --  "E5",      659.26,  1517,  76
    --  "F5",      698.46,  1432,  77
    --  "F#5/Gb5", 739.99,  1351,  78
    --  "G5",      783.99,  1276,  79
    --  "G#5/Ab5", 830.61,  1204,  80
    --  "A5",      880,     1136,  81
    --  "A#5/Bb5", 932.33,  1073,  82
    --  "B5",      987.77,  1012,  83
    --  "C6",      1046.5,  956,   84
    --  "C#6/Db6", 1108.73, 902,   85
    --  "D6",      1174.66, 851,   86
    --  "D#6/Eb6", 1244.51, 804,   87
    --  "E6",      1318.51, 758,   88
    --  "F6",      1396.91, 716,   89
    --  "F#6/Gb6", 1479.98, 676,   90
    --  "G6",      1567.98, 638,   91
    --  "G#6/Ab6", 1661.22, 602,   92
    --  "A6",      1760,    568,   93
    --  "A#6/Bb6", 1864.66, 536,   94
    --  "B6",      1975.53, 506,   95
    --  "C7",      2093,    478,   96
    --  "C#7/Db7", 2217.46, 451,   97
    --  "D7",      2349.32, 426,   98
    --  "D#7/Eb7", 2489.02, 402,   99
    --  "E7",      2637.02, 379,   100
    --  "F7",      2793.83, 358,   101
    --  "F#7/Gb7", 2959.96, 338,   102
    --  "G7",      3135.96, 319,   103
    --  "G#7/Ab7", 3322.44, 301,   104
    --  "A7",      3520,    284,   105
    --  "A#7/Bb7", 3729.31, 268,   106
    --  "B7",      3951.07, 253,   107
    --  "C8",      4186.01, 239,   108
    --  "C#8/Db8", 4434.92, 225,   109
    --  "D8",      4698.64, 213,   110
    --  "D#8/Eb8", 4978.03, 201,   111

    Power_Vref :            Natural := 504;                     -- Voltage Reference (5.04 Volts)

    MIDI_Low :              constant MIDI.Note_Type := 12;      -- Lowest midi note supported
    MIDI_High :             constant MIDI.Note_Type := 108;     -- Highest midi note supported

    type DAC_Unit is (
        DAC_A,              -- Control Voltage (CV),    Labeled "Pitch (CV)" on front panel
        DAC_B,              -- Bend                     Labeled "Bend" on front panel
        DAC_C,              -- Velocity                 Labeled "Velocity" on front panel
        DAC_D               -- Sysex: ADSR etc.         Underneath the "Calibrate" Button, which is Reset
    );

    DAC_CV :                DAC_Unit renames DAC_A;
    DAC_Bend :              DAC_Unit renames DAC_B;
    DAC_Velocity :          DAC_Unit renames DAC_C;
    DAC_ADSR :              DAC_Unit renames DAC_D;

    LED_Note_On_Bit :       constant := 0;      -- Port B
    LED_MIDI_Traffic_Bit :  constant := 1;      -- Port B
    SS_DAC_AB_Bit :         constant := 2;      -- Port B
    LED_Arduino_Bit :       constant := 5;      -- Port B

    Sig_Trigger_Bit :       constant := 2;      -- Port D   Labeled "Trigger" on front panel
    Sig_Gate_Bit :          constant := 3;      -- Port D   Labeled "Gate" on front panel
    SS_DAC_CD_Bit :         constant := 4;      -- Port D
    Inp_Button_Bit :        constant := 5;      -- Port D
    LED_Trigger_Bit :       constant := 6;      -- Port D
    LED_Gate_Bit :          constant := 7;      -- Port D

    BV_LED_Note_On :        Boolean renames MCU.PORTB_Bits(LED_Note_On_Bit);
    BV_LED_MIDI_Traffic:    Boolean renames MCU.PORTB_Bits(LED_MIDI_Traffic_Bit);
    BV_SS_DAC_AB :          Boolean renames MCU.PORTB_Bits(SS_DAC_AB_Bit);
    BV_LED_Arduino :        Boolean renames MCU.PORTB_Bits(LED_Arduino_Bit);

    BV_Inp_Button :         Boolean renames MCU.PORTD_Bits(Inp_Button_Bit);
    pragma Unreferenced(BV_Inp_Button);

    BV_Sig_Gate :           Boolean renames MCU.PORTD_Bits(Sig_Gate_Bit);
    BV_SS_DAC_CD :          Boolean renames MCU.PORTD_Bits(SS_DAC_CD_Bit);
    BV_Sig_Trigger :        Boolean renames MCU.PORTD_Bits(Sig_Trigger_Bit);
    BV_LED_Trigger :        Boolean renames MCU.PORTD_Bits(LED_Trigger_Bit);
    BV_LED_Gate :           Boolean renames MCU.PORTD_Bits(LED_Gate_Bit);

    Baud_Divisor :          constant := 31;     -- 31250 MIDI Baud Rate

    type Bit_Device_Address is (
        LED_Note_On,            -- Note_On_LED
        LED_MIDI_Traffic,       -- MIDI_Traffic_LED
        LED_Trigger,            -- Trigger_LED
        LED_Gate,               -- Gate_LED
        LED_Arduino,            -- MCU.PortB_Bits(5) -- Standard Arduino LED
        Sig_Trigger,            -- Output Trigger signal
        Sig_Gate                -- Output Gate signal
    );

    LED_Traffic_Ticks :     constant := 64;         -- Hold Traffic LED for 64 2ms ticks
    LED_Trigger_Ticks :     constant := 08;         -- Hold Trigger LED for 8 ticks

    LED_Events_Context :    AVR.Threads.Context(256);

    Ctl_Mutex :             AVR.Threads.Mutex;      -- Mutex for control adjustments

    Omni :                  Boolean := True;        -- Respond to all channels (else just # 1)
    Synth_Channel :         MIDI.Channel_Type := 1; -- When Omni Off, respond to this channel only
    Local :                 Boolean := True;        -- When false, don't respond to messages

    ADSR_Attack :           constant :=  82;        -- Ctl # for adjusting attack  (slider 1)
    ADSR_Decay :            constant :=  83;        -- Ctl # for adjusting decay   (slider 2)
    ADSR_Sustain :          constant :=  28;        -- Ctl # for adjusting sustain (slider 3)
    ADSR_Release :          constant :=  29;        -- Ctl # for adjusting release (slider 4)

--  Filter_Control :        constant :=  81;        -- Filter Envelope (slider 5)
--  Cutoff_Control :        constant :=  74;        -- Cutoff Control (slider 6)
--  Resonance_Control :     constant :=  71;        -- Resonance Control (slider 7)
    Breath_Control :        constant :=   2;        -- Breath Control (slider 8)

    type ADSR_Type is (
        Nil,
        Attack,
        Decay,
        Sustain,
        Release
    );
    type ADSR_Array is array(ADSR_Type range Attack..Release) of Interfaces.Unsigned_32;

    ADSR :                  Boolean := True;        -- True when ADSR active
    ADSR_Params :           ADSR_Array;             -- Attack, Decay, Sustain and Release parameters

    pragma Volatile(ADSR_Params);

    Notes_Are_Held_On :     Boolean := False;       -- True when Breath_Control >= 127

    pragma Volatile(Notes_Are_Held_On);

    type LED_On_Msg_Type is
        record
            Empty :         Boolean := True;
            MIDI :          Boolean := False;
            Trigger :       Boolean := False;
            Note_Off :      Boolean := False;
        end record;

    LED_Msg :               LED_On_Msg_Type;
    Msg_Mutex :             AVR.Threads.Mutex;   -- Mutex for this object
    Msg_Event :             AVR.Threads.Event;   -- Notifying event
    DAC_Mutex :             AVR.Threads.Mutex;   -- Single thread DAC writes

    type Note_Array is array(Positive range <>) of MIDI.Note_Type;

    Rollover :              Note_Array(1..10) := ( 0, others => 0 );
    Last_Velocity :         MIDI.Velocity_Type := 0;

    pragma Volatile(Rollover);
    pragma Volatile(Last_Velocity);

    procedure Shift_Right(Notes : in out Note_Array);
    procedure Shift_Left(Notes : in out Note_Array);
    function  Is_Empty(Notes : Note_Array) return Boolean;
    procedure Register_Note(Note : MIDI.Note_Type; On : Boolean; Off_Event : out Boolean);
    procedure Clear_Rollover;

    procedure Set_On(Device : Bit_Device_Address; Data_Bit : Boolean);
    procedure Note_Off;
    procedure DAC_Put(DAC : DAC_Unit; CV : MCP4922.Value_Type; Shutdown : Boolean := False);
    procedure Enable_ADSR(On : Boolean);
    function MIDI_to_CV(V : Interfaces.Unsigned_16) return MCP4922.Value_Type;

    procedure All_Sounds_Off(Channel : MIDI.Channel_Type; Value : MIDI.Value_Type);

    ------------------------------------------------------------------
    -- Reset the Rollover Array (for "All Notes Off")
    ------------------------------------------------------------------

    procedure Clear_Rollover is
    begin
        Rollover := ( 0, others => 0 );
    end Clear_Rollover;

    ------------------------------------------------------------------
    -- Shift Notes Right in Rollover Array
    ------------------------------------------------------------------
    procedure Shift_Right(Notes : in out Note_Array) is
    begin

        for X in reverse Notes'First..Notes'Last-1 loop
            Notes(X+1) := Notes(X);
        end loop;

        Notes(Notes'First) := 0;

    end Shift_Right;
    
    ------------------------------------------------------------------
    -- Shift Notes Left in Rollover Array
    ------------------------------------------------------------------
    procedure Shift_Left(Notes : in out Note_Array) is
    begin

        for X in Notes'First+1..Notes'Last loop
            Notes(X-1) := Notes(X);
        end loop;

        Notes(Notes'Last) := 0;

    end Shift_Left;
    
    ------------------------------------------------------------------
    -- Test if the Rollover Array is Empty
    ------------------------------------------------------------------
    function  Is_Empty(Notes : Note_Array) return Boolean is
        use MIDI;
    begin

        for X in Notes'Range loop
            if Notes(X) /= 0 then
                return False;
            end if;
        end loop;

        return True;

    end Is_Empty;

    ------------------------------------------------------------------
    -- Register a Note in the Rollover Array
    ------------------------------------------------------------------
    procedure Register_Note(Note : MIDI.Note_Type; On : Boolean; Off_Event: out Boolean) is
        use MIDI;

        Was_Note : MIDI.Note_Type := Rollover(Rollover'First);
    begin

        for X in Rollover'Range loop
            if Rollover(X) = Note then
                Rollover(X) := 0;
            end if;
        end loop;

        if On then
            if Rollover(Rollover'First) /= 0 then
                Shift_Right(Rollover);
            end if;
            Rollover(Rollover'First) := Note;
        end if;

        for X in Rollover'Range loop
            while Rollover(X) = 0 loop
                Shift_Left(Rollover(X..Rollover'Last));
                exit when Is_Empty(Rollover(X..Rollover'Last));
            end loop;
        end loop;

        Off_Event := Rollover(Rollover'First) = 0 and Was_Note /= 0;

    end Register_Note;


    ------------------------------------------------------------------
    -- Schedule a LED On/Off Event
    ------------------------------------------------------------------
    procedure Put_LED_Msg(MIDI, Trigger, Note_Off : Boolean := False) is
        use AVR.Threads;
    begin

        Acquire(Msg_Mutex);

        if MIDI then
            LED_Msg.MIDI := True;
        end if;

        if Trigger then
            LED_Msg.Trigger  := True;
            LED_Msg.Note_Off := False;
        end if;
        
        if ( not Trigger ) and Note_Off then
            LED_Msg.Note_Off := True;
        end if;

        LED_Msg.Empty := False;

        Release(Msg_Mutex);
        Wake_All(Msg_Event);

    end Put_LED_Msg;

    ------------------------------------------------------------------
    -- Get a LED Event Msg
    ------------------------------------------------------------------
    procedure Get_LED_Msg(MIDI, Trigger, Note_Off : out Boolean; Timeout : Interfaces.Unsigned_32) is
        use AVR.Threads, Interfaces;

        OK : Boolean;
    begin

        MIDI    := False;
        Trigger := False;
        Note_Off := False;

        Wait_And_Clear(Msg_Event,OK,Ticks_T(Timeout));
        Acquire(Msg_Mutex);

        MIDI            := LED_Msg.MIDI;
        Trigger         := LED_Msg.Trigger;
        Note_Off        := LED_Msg.Note_Off;

        LED_Msg.Empty   := True;
        LED_Msg.MIDI    := False;
        LED_Msg.Trigger := False;
        LED_Msg.Note_Off := False;
            
        Release(Msg_Mutex);
        
    end Get_LED_Msg;

    ------------------------------------------------------------------
    -- Linear Interpolation for ADSR Signal Generation
    ------------------------------------------------------------------
    function Linear_Interpolate(
        Elapsed, Ticks_Total :      Interfaces.Unsigned_32;
        Start_Value, End_Value :    MCP4922.Value_Type
    ) return MCP4922.Value_Type is
        use Interfaces, MCP4922;

        Value_Delta :   Unsigned_32;
        Interp_Value :  Unsigned_32;
    begin

        if Elapsed >= Ticks_Total then
            return End_Value;
        end if;

        if Start_Value <= End_Value then
            Value_Delta := Unsigned_32(End_Value - Start_Value);
            Interp_Value := ( Elapsed * Value_Delta )
                            / Unsigned_32(Ticks_Total) + Unsigned_32(Start_Value);
        else
            Value_Delta := Unsigned_32(Start_Value - End_Value);
            Interp_Value := Unsigned_32(Start_Value)
                            - ( Elapsed * Value_Delta ) / Unsigned_32(Ticks_Total);
        end if;

        if Interp_Value > Unsigned_32(MCP4922.Value_Type'Last) then
            Interp_Value := Unsigned_32(MCP4922.Value_Type'Last);
        end if;

        return MCP4922.Value_Type(Interp_Value);

    end Linear_Interpolate;

    ------------------------------------------------------------------
    -- Process the flashing and delayed turn off of LEDs
    ------------------------------------------------------------------
    procedure LED_Event_Thread is
        use Interfaces, MCP4922;

        Now :               Unsigned_32;
        Next :              Unsigned_32;
        Forever :           constant := 10_000;         -- Ticks from Now

        Got_MIDI :          Boolean;
        Got_Trigger :       Boolean;
        Got_Note_Off :      Boolean;

        Wait_Ticks :        Unsigned_32 := 0;
        Traffic :           Boolean := False;
        Traffic_Until :     Unsigned_32 := 0;
        Trigger :           Boolean := False;
        Trigger_Until :     Unsigned_32 := 0;
        
        ADSR_State :        ADSR_Type := Nil;
        ADSR_Started :      Unsigned_32 := 0;
        ADSR_Ticks :        Unsigned_32 := 0;

        Cur_Val :           MCP4922.Value_Type := 0;
        New_Val :           MCP4922.Value_Type := 0;
        Sus_Val :           MCP4922.Value_Type := 0;

        use MIDI, AVR.Threads;
    begin

        loop
            Get_LED_Msg(Got_MIDI,Got_Trigger,Got_Note_Off,Wait_Ticks);

            Acquire(Ctl_Mutex);
            if ADSR then
                Sus_Val := MIDI_to_CV(Interfaces.Unsigned_16(ADSR_Params(Sustain)));
            end if;
            Release(Ctl_Mutex);

            Now := Interfaces.Unsigned_32(AVR.Threads.Get_Timer_Ticks); -- Current time in ticks

            if Got_MIDI then
                ------------------------------------------------------
                -- Turn on "MIDI Traffic" LED for a while
                ------------------------------------------------------
                Set_On(LED_MIDI_Traffic,True);
                Traffic_Until := Now + LED_Traffic_Ticks;   -- Turn off time
                Traffic := True;
            end if;

            if Got_Trigger then
                ------------------------------------------------------
                -- Activate the Trigger Signal + LED
                ------------------------------------------------------
                Set_On(LED_Trigger,True);
                Set_On(Sig_Trigger,True);
                Trigger_Until := Now + LED_Trigger_Ticks;   -- Turn off time
                Trigger := True;

                Acquire(Ctl_Mutex);
                if ADSR then
                    --------------------------------------------------
                    -- If ADSR is enabled, then start that cycle
                    --------------------------------------------------
                    ADSR_State := Attack;                   -- Attack phase
                    Cur_Val := 0;                           -- Start from 0 volts
                    DAC_Put(DAC_ADSR,Cur_Val);              -- Set ADSR level
                    ADSR_Started := Now;                    -- Starting from now
                end if;
                Release(Ctl_Mutex);
            end if;

            Acquire(Ctl_Mutex);
            if Got_Note_Off and then ADSR then
                ------------------------------------------------------
                -- The Note off event marks the beginning of the
                -- ADSR Release event
                ------------------------------------------------------
                ADSR_State := Release;                      -- Release phase
                ADSR_Started := Now;                        -- Starting from now
                Cur_Val := New_Val;
            end if;
            Release(Ctl_Mutex);

            if Traffic and then Delta_Time(Traffic_Until,Now) >= 0 then
                ------------------------------------------------------
                -- Turn off MIDI Traffic LED
                ------------------------------------------------------
                Set_On(LED_MIDI_Traffic,False);
                Traffic_Until := 0;
                Traffic := False;
            end if;

            if Trigger and then Delta_Time(Trigger_Until,Now) >= 0 then
                ------------------------------------------------------
                -- Turn off Trigger LED
                ------------------------------------------------------
                Set_On(LED_Trigger,False);
                Set_On(Sig_Trigger,False);
                Trigger_Until := 0;
                Trigger := False;
            end if;

            Acquire(Ctl_Mutex);

            if ADSR and then ADSR_State /= Nil then
                ------------------------------------------------------
                -- Process an ADSR Event
                ------------------------------------------------------
                ADSR_Ticks := Interfaces.Unsigned_32(Delta_Time(ADSR_Started,Now));
                Next := Now + 1;                                -- Alter ADSR signal with each tick

                case ADSR_State is

                    when Attack =>
                        ----------------------------------------------
                        -- Ramp ADSR Voltage from 0 to Max
                        ----------------------------------------------
                        New_Val := Linear_Interpolate(ADSR_Ticks,ADSR_Params(Attack),
                                                      0,MCP4922.Value_Type'Last);
                        DAC_Put(DAC_ADSR,New_Val);

                        if ADSR_Ticks >= ADSR_Params(Attack) then
                            ADSR_State := Decay;                -- Start decay phase
                            Cur_Val := New_Val;                 -- Current Voltage state
                            ADSR_Started := Now;
                        end if;

                    when Decay =>
                        ----------------------------------------------
                        -- Ramp Voltage from Max to Sustain level
                        ----------------------------------------------
                        New_Val := Linear_Interpolate(ADSR_Ticks,ADSR_Params(Decay),Cur_Val,Sus_Val);
                        DAC_Put(DAC_ADSR,New_Val);

                        if ADSR_Ticks >= ADSR_Params(Decay) then
                            ADSR_State := Sustain;
                            Cur_Val := New_Val;
                        end if;

                    when Sustain =>
                        ----------------------------------------------
                        -- Sustain Phase - Hold & Wait for Note Off Event
                        ----------------------------------------------
                        Next := Now + Forever;

                    when Release =>
                        if not Notes_Are_Held_On then
                            ------------------------------------------
                            -- Ramp from Sustain Level down to Zero
                            ------------------------------------------
                            New_Val := Linear_Interpolate(ADSR_Ticks,ADSR_Params(Release),Cur_Val,0);
                            DAC_Put(DAC_ADSR,New_Val);

                            if ADSR_Ticks >= ADSR_Params(Release) then
                                Cur_Val := 0;
                                ADSR_State := Nil;
                                Note_Off;
                            end if;
                        else
                            ------------------------------------------
                            -- When notes are held on, just exit this
                            -- state.
                            ------------------------------------------
                            ADSR_State := Nil;
                        end if;

                    when Nil =>
                        Next := Now + Forever;          -- Should not get here

                end case;
            else
                Next := Now + Forever;
            end if;

            Release(Ctl_Mutex);

            ----------------------------------------------------------
            -- Now schedule the earliest next event
            ----------------------------------------------------------

            if Traffic and then Delta_Time(Next,Traffic_Until) < 0 then
                Next := Traffic_Until;
            end if;

            if Trigger and then Delta_Time(Next,Trigger_Until) < 0 then
                Next := Trigger_Until;
            end if;

            Wait_Ticks := Interfaces.Unsigned_32( Delta_Time(Now,Next) );

        end loop;

    end LED_Event_Thread;

    ------------------------------------------------------------------
    -- Compute the DAC Value Needed to Achieve Voltage
    ------------------------------------------------------------------
    function Voltage(Vout, Vref : Natural) return MCP4922.Value_Type is
        use Interfaces, MCP4922;

        Value : Unsigned_32;
    begin

        Value := Unsigned_32(Vout) * 4096 / Unsigned_32(Vref);
        if Value >= 4096 then
            return 4095;
        else
            return Value_Type(Value);
        end if;

    end Voltage;
                                                                                    
    ------------------------------------------------------------------
    -- Given a MIDI Note, Compute 12-bit DAC Value Required
    ------------------------------------------------------------------
    function Note_to_CV(Note : MIDI.Note_Type) return MCP4922.Value_Type is
        use MIDI;

        Note_Delta : Natural;
    begin

        if Note < MIDI_Low or else Note > MIDI_High then
            return 0;       -- Out of range
        end if;

        Note_Delta := Natural(Note) - Natural(MIDI_Low);
        return Voltage(Note_Delta * 5,Power_Vref);

    end Note_to_CV;

    ------------------------------------------------------------------
    -- Convert other MIDI Value (0..127) to DAC Value
    ------------------------------------------------------------------
    function MIDI_to_CV(V : Interfaces.Unsigned_16) return MCP4922.Value_Type is
        use Interfaces;

        U32 : Unsigned_32 := Unsigned_32(V) * Unsigned_32(MCP4922.Value_Type'Last) / 127;
    begin

        return MCP4922.Value_Type(U32);

    end MIDI_to_CV;

    ------------------------------------------------------------------
    -- Set Bit for Device
    ------------------------------------------------------------------
    procedure Set_On(Device : Bit_Device_Address; Data_Bit : Boolean) is
    begin
        case Device is
            when LED_Note_On =>
                BV_LED_Note_On      := Data_Bit;            -- Active High
            when LED_MIDI_Traffic =>
                BV_LED_MIDI_Traffic := Data_Bit;            -- Active High
            when LED_Trigger =>
                BV_LED_Trigger      := Data_Bit;            -- Active High
            when LED_Gate =>
                BV_LED_Gate         := Data_Bit;            -- Active High
            when Sig_Trigger =>
                BV_Sig_Trigger      := Data_Bit;            -- Active High
            when Sig_Gate =>
                BV_Sig_Gate         := Data_Bit;            -- Active High
            when LED_Arduino =>
                BV_LED_Arduino      := Data_Bit;            -- Active High
        end case;
    end Set_On;

    ------------------------------------------------------------------
    -- Set all LEDs to a State
    ------------------------------------------------------------------
    procedure Set_All_LEDs(State : Boolean) is
    begin
        Set_On(LED_Note_On,State);
        Set_On(LED_MIDI_Traffic,State);
        Set_On(LED_Trigger,State);
        Set_On(LED_Gate,State);
        Set_On(LED_Arduino,State);
    end Set_All_LEDs;

    ------------------------------------------------------------------
    -- Return DAC_A or DAC_B to address device in MCP4922 Chip
    ------------------------------------------------------------------
    function Unit(DAC : DAC_Unit) return MCP4922.Unit_Type is
    begin
        case DAC is
            when DAC_A | DAC_C =>
                return MCP4922.DAC_A;
            when DAC_B | DAC_D =>
                return MCP4922.DAC_B;
        end case;
    end Unit;

    ------------------------------------------------------------------
    -- Activate /SS for DAC_C or DAC_D
    ------------------------------------------------------------------
    procedure SS_DAC_CD(Activate_Select : Boolean) is
    begin
        BV_SS_DAC_CD := Activate_Select xor True;          -- SS is Active Low
    end SS_DAC_CD; 

    ------------------------------------------------------------------
    -- Put a Message onto the SPI Bus (in Master Mode)
    ------------------------------------------------------------------
    procedure SPI_Put(DAC : DAC_Unit; Buffer : in out SPI.SPI_Data_Type) is
        SS_Proc :   SPI.Master.SS_Status_Proc;
    begin

        case DAC is
            when DAC_A | DAC_B =>
                SS_Proc := SPI.Master.SS_Proc'Access;
            when DAC_C | DAC_D =>
                SS_Proc := SS_DAC_CD'Access;
        end case;

        AVR.Threads.Acquire(DAC_Mutex);
        AVR.SPI.Master.Master_IO(Buffer,SS_Proc);
        AVR.Threads.Release(DAC_Mutex);

    end SPI_Put;

    ------------------------------------------------------------------
    -- Tristate or enable DAC Unit
    ------------------------------------------------------------------
    procedure DAC_Enable(DAC : DAC_Unit; Enable : Boolean) is
        Buf : SPI.SPI_Data_Type(1..2);
    begin

        MCP4922.Format(Unit(DAC),0,Buf,Shutdown => Enable xor True);
        SPI_Put(DAC,Buf);

    end DAC_Enable;

    ------------------------------------------------------------------
    -- Send a Value to the Selected DAC
    ------------------------------------------------------------------
    procedure DAC_Put(DAC : DAC_Unit; CV : MCP4922.Value_Type; Shutdown : Boolean := False) is
        Buf : SPI.SPI_Data_Type(1..2);
    begin

        MCP4922.Format(Unit(DAC),CV,Buf,Shutdown => Shutdown);
        SPI_Put(DAC,Buf);

    end DAC_Put;

    ------------------------------------------------------------------
    -- Initialize ADSR Settings
    ------------------------------------------------------------------
    procedure Initialize_ADSR is
    begin

        ADSR                 := True;   -- Disable
        ADSR_Params(Attack)  :=  8;     -- Attack time in ticks
        ADSR_Params(Decay)   :=  8;     -- Decay time in ticks
        ADSR_Params(Sustain) := 64;     -- Relative Sustain voltage level (0..127)
        ADSR_Params(Release) := 12;     -- Release time in ticks
        
        Enable_ADSR(ADSR);

    end Initialize_ADSR;

    ------------------------------------------------------------------
    -- Initialize for MIDI Input
    ------------------------------------------------------------------
    procedure Initialize is
        BV_DD_LED_Note_On :     Boolean renames MCU.DDRB_Bits(LED_Note_On_Bit);
        BV_DD_LED_MIDI_Traffic: Boolean renames MCU.DDRB_Bits(LED_MIDI_Traffic_Bit);
        BV_DD_SS_DAC_AB :       Boolean renames MCU.DDRB_Bits(SS_DAC_AB_Bit);
        BV_DD_LED_Arduino :     Boolean renames MCU.DDRB_Bits(LED_Arduino_Bit);

        BV_DD_Inp_Button :      Boolean renames MCU.DDRD_Bits(Inp_Button_Bit);
        BV_DD_Sig_Gate :        Boolean renames MCU.DDRD_Bits(Sig_Gate_Bit);
        BV_DD_SS_DAC_CD :       Boolean renames MCU.DDRD_Bits(SS_DAC_CD_Bit);
        BV_DD_Sig_Trigger :     Boolean renames MCU.DDRD_Bits(Sig_Trigger_Bit);
        BV_DD_LED_Trigger :     Boolean renames MCU.DDRD_Bits(LED_Trigger_Bit);
        BV_DD_LED_Gate :        Boolean renames MCU.DDRD_Bits(LED_Gate_Bit);
    begin

        BV_SS_DAC_AB            := True;

        MCU.DDRB_Bits           := ( others => DD_Input );
        MCU.DDRC_Bits           := ( others => DD_Input );
        MCU.DDRD_Bits           := ( others => DD_Input );

        BV_DD_LED_Note_On       := DD_Output;
        BV_DD_LED_MIDI_Traffic  := DD_Output;
        BV_DD_SS_DAC_AB         := DD_Output;
        BV_DD_LED_Arduino       := DD_Output;

        BV_DD_Inp_Button        := DD_Input;

        BV_DD_Sig_Gate          := DD_Output;
        BV_DD_SS_DAC_CD         := DD_Output;
        BV_DD_Sig_Trigger       := DD_Output;
        BV_DD_LED_Trigger       := DD_Output;
        BV_DD_LED_Gate          := DD_Output;

        Set_On(Sig_Trigger,False);                          -- Turn off trigger signal
        Set_On(Sig_Gate,False);                             -- Turn off gate signal

        BV_SS_DAC_AB            := True;                    -- Inactive
        BV_SS_DAC_CD            := True;                    -- Inactive

        Set_All_LEDs(True);

        AVR.UART.Init_Interrupt_Read(Baud_Divisor,False,Buffer_Access);

        AVR.SPI.Startup(SPI.By_4,SPI.Sample_Rising_Setup_Falling,   -- Activate SPI output
            MSB_First => True, Use_SS_Pin => True);

        DAC_Enable(DAC_CV,True);                            -- Enable CV output voltage
        DAC_Enable(DAC_Bend,True);                          -- Enable Bend output voltage
        DAC_Enable(DAC_Velocity,True);                      -- Enable Velocity output voltage
        DAC_Enable(DAC_ADSR,False);                         -- Enabled by Sysex message

        Omni := True;

        Initialize_ADSR;

        DAC_Put(DAC_Velocity,MIDI_to_CV(0));                -- Set to zero 
        DAC_Put(DAC_Bend,MCP4922.Value_Type(2048));         -- Bend Zero value
        DAC_Put(DAC_CV,Note_to_CV(MIDI_High));              -- Emit high pitch for calibration

    end Initialize;

    ------------------------------------------------------------------
    -- Turn off current note, if any
    ------------------------------------------------------------------
    procedure Note_Off is
    begin

        Set_On(LED_Note_On,False);
        Set_On(LED_Gate,False);
        Set_On(Sig_Gate,False);

    end Note_Off;

    ------------------------------------------------------------------
    -- Post a Note On Event
    ------------------------------------------------------------------
    procedure Post_Note(Note : MIDI.Note_Type; Velocity : MIDI.Velocity_Type) is
        use Interfaces;
    begin

        Last_Velocity := Velocity;

        Set_On(LED_Note_On,True);
        Set_On(LED_Gate,True);
        Set_On(Sig_Gate,True);

        Put_LED_Msg(MIDI=>True,Trigger=>True);
        DAC_Put(DAC_Velocity,MIDI_to_CV(Unsigned_16(Velocity)));
        DAC_Put(DAC_CV,Note_to_CV(Note));

    end Post_Note;

    ------------------------------------------------------------------
    -- Return True if the Channel (or Omni mode) addresses us
    ------------------------------------------------------------------
    function Is_Channel(Channel : MIDI.Channel_Type; Ignore_Local : Boolean := False) return Boolean is
        use MIDI;
    begin

        if Local or else Ignore_Local then
            return Channel = Synth_Channel or else Omni;
        else
            return False;
        end if;

    end Is_Channel;

    ------------------------------------------------------------------
    -- Enable or Shutdown ADSR
    ------------------------------------------------------------------
    procedure Enable_ADSR(On : Boolean) is
    begin

        if On and not ADSR then
            DAC_Put(DAC_ADSR,0,Shutdown => False);
        end if;

        if not On and ADSR then
            DAC_Put(DAC_ADSR,0,Shutdown => True);
        end if;

        ADSR := On;

    end Enable_ADSR;

    ------------------------------------------------------------------
    -- Adjust Synth Controls
    ------------------------------------------------------------------
    procedure Control_Adjust(Channel : MIDI.Channel_Type; Control : MIDI.Control_Type; Value : MIDI.Value_Type) is
        use Interfaces, MIDI, AVR.Threads;
    begin

        if Is_Channel(Channel) then
            Acquire(Ctl_Mutex);

            case Control is
                when ADSR_Attack =>
                    ADSR_Params(Attack) := Interfaces.Unsigned_32(Value);   -- Ticks
                    Enable_ADSR(ADSR_Params(Attack) /= 0);
                    
                when ADSR_Decay =>
                    ADSR_Params(Decay)  := Interfaces.Unsigned_32(Value);   -- Ticks
                    Enable_ADSR(True);

                when ADSR_Sustain =>
                    ADSR_Params(Sustain) := Interfaces.Unsigned_32(Value);  -- 0..127 => relative voltage level for sustain
                    Enable_ADSR(True);

                when ADSR_Release =>
                    ADSR_Params(Release) := Interfaces.Unsigned_32(Value);  -- Ticks
                    Enable_ADSR(True);

                when Breath_Control =>
                    declare
                        Was_Held :  Boolean := Notes_Are_Held_On;
                    begin
                        Notes_Are_Held_On := Value >= 127;
                        if Was_Held = True and Notes_Are_Held_On = False then
                            All_Sounds_Off(1,0);
                        end if;
                    end;

                when others =>
                    null;
            end case;

            Release(Ctl_Mutex);
        end if;
        
    end Control_Adjust;

    ------------------------------------------------------------------
    -- Local Control
    ------------------------------------------------------------------
    procedure Local_Control(Channel : MIDI.Channel_Type; Value : MIDI.Value_Type) is
        use MIDI, AVR.Threads;
    begin

        if Is_Channel(Channel,Ignore_Local=>True) then
            Acquire(Ctl_Mutex);

            Local := Value /= 0;        -- False is "local control off" else "on"
            ----------------------------------------------------------
            -- Normally the Local Control Value is:
            --
            --  0   -   Off
            --  127 -   On
            --
            --  but here, if we get a value 1..15, then we turn omni
            --  off, and set channel = value
            ----------------------------------------------------------
            if Value in 1..15 then
                Omni          := False;
                Synth_Channel := Channel_Type(Value);
            end if;

            Release(Ctl_Mutex);
        end if;
        
    end Local_Control;

    ------------------------------------------------------------------
    -- Reset the Controller
    ------------------------------------------------------------------
    procedure Reset_Controller(Channel : MIDI.Channel_Type; Value : MIDI.Value_Type) is
        use MIDI, AVR.Threads;
    begin

        pragma Unreferenced(Value);

        if Is_Channel(Channel) then
            Acquire(Ctl_Mutex);

            Note_Off;
            Omni            := True;
            Synth_Channel   := 1;
            Local           := True;
            Initialize_ADSR;

            Release(Ctl_Mutex);
        end if;
        
    end Reset_Controller;

    ------------------------------------------------------------------
    -- Process All Notes/Sounds Off Message
    ------------------------------------------------------------------
    procedure All_Sounds_Off(Channel : MIDI.Channel_Type; Value : MIDI.Value_Type) is
        use MIDI;
    begin

        pragma Unreferenced(Value);

        if Is_Channel(Channel) then
            Note_Off;
            Clear_Rollover;
        end if;
        
    end All_Sounds_Off;

    ------------------------------------------------------------------
    -- Turn Omni On/Off
    ------------------------------------------------------------------
    procedure Omni_Control(Channel : MIDI.Channel_Type; Value : MIDI.Value_Type; Omni_On : Boolean) is
        use MIDI, AVR.Threads;
    begin

        pragma Unreferenced(Value);

        if Is_Channel(Channel) then
            Note_Off;
            Acquire(Ctl_Mutex);
            Omni := Omni_On;
            Release(Ctl_Mutex);
        end if;

    end Omni_Control;

    ------------------------------------------------------------------
    -- Process a Bend Message
    ------------------------------------------------------------------
    procedure Bend(Channel : MIDI.Channel_Type; Bend : MIDI.Bend_Type) is
        use Interfaces, MIDI, MCP4922;

        IV : Integer_32 := Integer_32(Bend);
    begin

        if Is_Channel(Channel) then
            ----------------------------------------------------------
            -- Radium Pitch wheel seems limited to -8192..8191 :
            ----------------------------------------------------------
            if IV < -8192 then
                IV := -8192;
            elsif IV > 8191 then
                IV := 8191;
            end if;
            IV := ( IV + 8192 ) / 4;        -- Scale to 0..4095
            DAC_Put(DAC_Bend,MCP4922.Value_Type(IV));
        end if;

    end Bend;

    ------------------------------------------------------------------
    -- Note On/Off Event Handler
    ------------------------------------------------------------------
    procedure Note_On(Channel : MIDI.Channel_Type; Note : MIDI.Note_Type; Velocity : MIDI.Velocity_Type; Note_On : Boolean) is
        use MIDI;

        Was_Note :  MIDI.Note_Type := Rollover(Rollover'First);
        Off_Event : Boolean;
    begin

        if Is_Channel(Channel) then
            Register_Note(Note,Note_On,Off_Event);
            if Note_On then
                Post_Note(Note,Velocity);
            else
                if not Notes_Are_Held_on then
                    if Off_Event then
                        if not ADSR then
                            Note_Off;
                        else
                            Put_LED_Msg(Note_Off => True);  -- Start ADSR Release
                        end if;
                    elsif Rollover(Rollover'First) /= Was_Note then
                        Post_Note(Rollover(Rollover'First),Last_Velocity);
                    end if;
                end if;
            end if;
        end if;

    end Note_On;

    ------------------------------------------------------------------
    -- Perform LED Test
    ------------------------------------------------------------------
    procedure Power_On_Test is
        use Interfaces;

        Bits :  Unsigned_8 := 16#08#;
    begin

        BV_LED_Arduino := True;

        AVR.Threads.Sleep(480);
        Set_All_LEDs(False);

        for X in 1..Unsigned_8(10) loop
            Set_On(LED_MIDI_Traffic,   ( Bits and 16#08# ) /= 0);
            Set_On(LED_Note_On,        ( Bits and 16#04# ) /= 0);
            Set_On(LED_Gate,           ( Bits and 16#02# ) /= 0);
            Set_On(LED_Trigger,        ( Bits and 16#01# ) /= 0);

            AVR.Threads.Sleep(64);

            Bits := Shift_Right(Bits,1);
            if Bits = 0 then
                Bits := 16#08#;
            end if;
        end loop;        

        Set_All_LEDs(False);

        BV_LED_Arduino := True;

    end Power_On_Test;

    ------------------------------------------------------------------
    -- Read a MIDI Byte
    ------------------------------------------------------------------
    procedure Read_Byte(Byte : out Interfaces.Unsigned_8) is
        use Interfaces;
    begin

        Byte := Unsigned_8(AVR.UART.Get_Raw);
        Put_LED_Msg(MIDI=>True);

    end Read_Byte;

    ------------------------------------------------------------------
    -- Idle Procedure
    ------------------------------------------------------------------
    procedure Idle is
    begin
        AVR.Threads.Yield;
    end Idle;

    ------------------------------------------------------------------
    -- Main Synth Routine
    ------------------------------------------------------------------
    procedure Synthesizer is
        use MIDI, MIDI.Receiver;

        IO :    IO_Context;         -- MIDI I/O Context
        RX :    Recv_Context;       -- MIDI Messages Context
        Reader: Read_Byte_Proc := Read_Byte'Access;
    begin

        AVR.Threads.Set_Timer(AVR.Timer2.Scale_By_256,Timer_Compare);           -- tick every 2ms

        Initialize;
        Set_All_LEDs(True);
        Power_On_Test;

        AVR.Threads.Start(LED_Events_Context,LED_Event_Thread'Access);

--        MIDI.Initialize(IO,Read_Byte'Access);
        MIDI.Initialize(IO,Reader);
        MIDI.Receiver.Register_Note_On_Off(RX,Note_On'Access);
        MIDI.Receiver.Register_Bend(RX,Bend'Access);
        MIDI.Receiver.Register_Omni(RX,Omni_Control'Access);

        MIDI.Receiver.Register_All_Sounds_Off(RX,All_Sounds_Off'Access);
        MIDI.Receiver.Register_All_Notes_Off(RX,All_Sounds_Off'Access);
        MIDI.Receiver.Register_Reset_Controller(RX,Reset_Controller'Access);
        MIDI.Receiver.Register_Local_Controller(RX,Local_Control'Access);
        MIDI.Receiver.Register_Unsupported_Control(RX,Control_Adjust'Access);

        MIDI.Receiver.Register_Idle(RX,Idle'Access);

        loop
            MIDI.Receiver.Receive(RX,IO,32);
        end loop;

    end Synthesizer;

end Synth;
