-- pcd8544.ads - Driver for PCD8544 Related LCDs (Nokia 5110)
--
-- (C) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;
use  Interfaces;

package pcd8544 is
    pragma Pure;

    type IO_Pin is (
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
        end record;

end pcd8544;
