-- PCD8544.ads - Driver for PCD8544 Related LCDs (Nokia 5110)
--
-- (C) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991
--
-- NOTES:
--
--  0.  The Nokia-5110 LCD display uses the PCD8544 controller chip.
--  1.  This is a "text only" driver interface:
--          6 lines (0-5)
--          14 columns (0-13)
--  2.  This supports "horizontal mode" (landscape) only, even though
--      the LCD controller will support portrait mode.
--  3.  This driver uses "bit-bang" operations, since the interface to
--      the PCD8544 is not timing critical, freeing up the SPI bus
--      for more demanding peripherals.
--  4.  The LCD requires 5 pins to drive it (excluding power):
--          i)   /CE        Chip enable
--          ii)  /RESET     Reset
--          iii) Data/Cmd   Data or /Command select
--          iv)  DataIn     Serial data in (to LCD)
--          v)   Clock      Serial clock in (to LCD)
--  5.  A user procedure is used to activate any/all of the required
--      I/O pins. This allows this package to support any I/O configuration.
--  6.  Due to #5, you can share pins iii, iv and v with other peripherals,
--      provided that /CE and /RESET remain inactive while you do so.
--  7.  No underline, inverse or other video attributes are supported. This
--      keeps the RAM (buffer) requirements low (6x14=84 bytes).
--  8.  Keep in mind that the PCD8544 is a 3 Volt part and that the AVR chip
--      is often NOT (5 Volt). Depending upon your MCU, you may need to provide
--      5V to 3V interfacing hardware.
--
--  See software usage info at the end of this file.

with Interfaces;
use  Interfaces;

package PCD8544 is
    pragma Pure;

    type IO_Pin is (
        Configure,      -- Callback to "configure" all pins
        CE,             -- Chip Enable
        Reset,          -- /Reset
        DataCmd,        -- Data/Command
        DataIn,         -- Serial Data In
        Clock           -- Serial Clock
    );

    type Set_IO_Proc is access
        procedure(Pin : IO_Pin; State : Boolean);

    type Vop_Type is new Interfaces.Unsigned_8 range 0..16#7F#;
    type TC_Type  is new Interfaces.Unsigned_8 range 0..3;
    type Bias_Type is new Interfaces.Unsigned_8 range 0..7;

    type X_Coord  is new Interfaces.Unsigned_8 range 0..13;
    type Y_Coord  is new Interfaces.Unsigned_8 range 0..5;

    type Display_Mode is (
        Blank,          -- No display
        Normal,         -- Black pixels on light background
        AllPixelsOn,    -- All pixels "on"
        Inverse         -- Light pixels on dark background
    );

    ------------------------------------------------------------------
    -- Initialization for LCD I/O
    ------------------------------------------------------------------

    type IO_Context is private;

    procedure Initialize(
        Context :       in out  IO_Context;
        IO_Proc :       in      Set_IO_Proc;
        Contrast :      in      Vop_Type  := 16#5F#;
        Temp_Coef :     in      TC_Type   := 0;
        Bias :          in      Bias_Type := 4
    );

    procedure Set_Vop(Context : in out IO_Context; Contrast : Vop_Type);
    procedure Set_TC(Context : in out IO_Context; Temp_Coef : TC_Type);
    procedure Set_Bias(Context : in out IO_Context; Bias : Bias_Type);
    procedure Set_Mode(Context : in out IO_Context; Mode : Display_Mode);
    procedure Power(Context : in out IO_Context; Down : Boolean);

    procedure Home(Context : in out IO_Context);
    procedure Set_Y(Context : in out IO_Context; Y : Y_Coord);
    procedure Set_X(Context : in out IO_Context; X : X_Coord);
    procedure Move(Context : in out IO_Context; Y : Y_Coord; X : X_Coord);

    procedure Clear(Context : in out IO_Context);           -- Clear screen and home cursor
    procedure Clear_to_Bot(Context : in out IO_Context);    -- Clear to end of screen
    procedure Clear_to_End(Context : in out IO_Context);    -- Clear to end of line

    function Y(Context : IO_Context) return Y_Coord;
    function X(Context : IO_Context) return X_Coord;

    procedure Put(Context : in out IO_Context; Ch : Character);
    procedure Put(Context : in out IO_Context; Text : String);
    procedure Put_Line(Context : in out IO_Context; Text : String);
    procedure Put_Line(Context : in out IO_Context);

private

    type Text_Buf is array(Y_Coord,X_Coord) of Character;

    ------------------------------------------------------------------
    -- I/O Context Object
    ------------------------------------------------------------------

    type IO_Context is
        record
            IO_Proc :       Set_IO_Proc;
            Contrast :      Vop_Type;
            Temp_Coef :     TC_Type;
            Bias :          Bias_Type;
            X :             X_Coord;
            Y :             Y_Coord;
            Buffer :        Text_Buf;
            Power_On :      Boolean;
        end record;

end PCD8544;

--  GENERAL INSTRUCTIONS:
--
--  Unless the corresponding signal line is inverted by hardware, set the
--  signal line exactly according to the argument "State", whether active
--  high or low. The callback assumes /CE and /RESET are active low, and all
--  other pins are active high.
--
--  When PCD8544.Initialize() is called, the user provided My_LCD_IO()
--  routine is called once with a "Configure" request. Use this to
--  configure your I/O pins as Outputs and establish a "high" initial
--  state on each pin (particularly /CE and /RESET).
--
--
--  with PCD8544;
--
--  procedure My_LCD_IO(Pin : IO_Pin; State : Boolean) is
--      use PCD8544;
--  begin
--
--       case Pin in
--          when Configure =>
--              ...configure all I/O pins used (ignore State here)...
--          when CE =>             -- Chip Enable
--              ...Set chip enable to State (active low assumed)...
--          when Reset,          -- /Reset
--              ...Set reset pin to State (active low assumed)...
--          when DataCmd,        -- Data/Command
--              ...Set data/command pin to State (Command is active low)...
--          when DataIn,         -- Serial Data In
--              ...Set serial data line to State (active high assumed)...
--          when Clock           -- Serial Clock
--              ...Set serial clock line to State (active high assumed)...
--      end case;
--
--  end My_LCD_IO;
--
--  procedure Main is
--      use Ada.Characters.Latin_1;
--      LCD : PCD8544.IO_Context;
--  begin
--
--      PCD8544.Initialize(LCD,My_LCD_IO'Access,...);
--      PCD8544.Put_Line(LCD,"Hello World!");
--      ...
--
-- End pcd8544.ads

