-- pcd8544.adb - Driver for PCD8544 Related LCDs (Nokia 5110)
--
-- (C) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Ada.Characters.Latin_1;

package body pcd8544 is

    ------------------------------------------------------------------
    -- Text Font
    ------------------------------------------------------------------

    type Pixel_Width is new Natural range 0..4;
    type Pixel_Row   is new Natural range 0..95;
    type Pixel_Array is array(Pixel_Row,Pixel_Width) of Unsigned_8;

    Font : constant Pixel_Array := (
        ( 16#00#, 16#00#, 16#00#, 16#00#, 16#00# ),   -- Space
        ( 16#00#, 16#00#, 16#2F#, 16#00#, 16#00# ),   -- !
        ( 16#00#, 16#07#, 16#00#, 16#07#, 16#00# ),   -- "
        ( 16#0A#, 16#1F#, 16#0A#, 16#1F#, 16#0A# ),   -- #
        ( 16#12#, 16#15#, 16#3F#, 16#15#, 16#09# ),   -- $
        ( 16#13#, 16#0B#, 16#04#, 16#1A#, 16#19# ),   -- %
        ( 16#0C#, 16#12#, 16#17#, 16#09#, 16#10# ),   -- &
        ( 16#00#, 16#00#, 16#07#, 16#00#, 16#00# ),   -- '
        ( 16#00#, 16#0C#, 16#12#, 16#21#, 16#00# ),   -- (
        ( 16#00#, 16#21#, 16#12#, 16#0C#, 16#00# ),   -- )
        ( 16#12#, 16#0C#, 16#1E#, 16#0C#, 16#12# ),   -- *
        ( 16#04#, 16#04#, 16#1F#, 16#04#, 16#04# ),   -- +
        ( 16#00#, 16#40#, 16#30#, 16#00#, 16#00# ),   -- ,
        ( 16#04#, 16#04#, 16#04#, 16#04#, 16#04# ),   -- -
        ( 16#00#, 16#00#, 16#10#, 16#00#, 16#00# ),   -- .
        ( 16#10#, 16#08#, 16#04#, 16#02#, 16#01# ),   -- /
        ( 16#0E#, 16#19#, 16#15#, 16#13#, 16#0E# ),   -- 0
        ( 16#00#, 16#12#, 16#1F#, 16#10#, 16#00# ),   -- 1
        ( 16#12#, 16#19#, 16#15#, 16#15#, 16#12# ),   -- 2
        ( 16#09#, 16#11#, 16#15#, 16#15#, 16#0B# ),   -- 3
        ( 16#0C#, 16#0A#, 16#09#, 16#1F#, 16#08# ),   -- 4
        ( 16#17#, 16#15#, 16#15#, 16#15#, 16#08# ),   -- 5
        ( 16#0E#, 16#15#, 16#15#, 16#15#, 16#08# ),   -- 6
        ( 16#11#, 16#09#, 16#05#, 16#03#, 16#01# ),   -- 7
        ( 16#0A#, 16#15#, 16#15#, 16#15#, 16#0A# ),   -- 8
        ( 16#02#, 16#15#, 16#15#, 16#15#, 16#0E# ),   -- 9
        ( 16#00#, 16#00#, 16#14#, 16#00#, 16#00# ),   -- :
        ( 16#00#, 16#20#, 16#14#, 16#00#, 16#00# ),   -- ;
        ( 16#00#, 16#04#, 16#0A#, 16#11#, 16#00# ),   -- <
        ( 16#00#, 16#0A#, 16#0A#, 16#0A#, 16#00# ),   -- =
        ( 16#00#, 16#11#, 16#0A#, 16#04#, 16#00# ),   -- >
        ( 16#02#, 16#01#, 16#59#, 16#09#, 16#06# ),   -- ?

        ( 16#3C#, 16#42#, 16#5A#, 16#56#, 16#1C# ),   -- @
        ( 16#1E#, 16#05#, 16#05#, 16#05#, 16#1E# ),   -- A
        ( 16#1F#, 16#15#, 16#15#, 16#15#, 16#0A# ),   -- B
        ( 16#0E#, 16#11#, 16#11#, 16#11#, 16#0A# ),   -- C
        ( 16#1F#, 16#11#, 16#11#, 16#11#, 16#0E# ),   -- D
        ( 16#1F#, 16#15#, 16#15#, 16#15#, 16#11# ),   -- E
        ( 16#1F#, 16#05#, 16#05#, 16#05#, 16#01# ),   -- F
        ( 16#0E#, 16#11#, 16#15#, 16#15#, 16#1C# ),   -- G
        ( 16#1F#, 16#04#, 16#04#, 16#04#, 16#1F# ),   -- H
        ( 16#00#, 16#11#, 16#1F#, 16#11#, 16#00# ),   -- I
        ( 16#08#, 16#10#, 16#10#, 16#0F#, 16#00# ),   -- J
        ( 16#1F#, 16#04#, 16#0A#, 16#11#, 16#00# ),   -- K
        ( 16#1F#, 16#10#, 16#10#, 16#10#, 16#10# ),   -- L
        ( 16#1F#, 16#02#, 16#0C#, 16#02#, 16#1F# ),   -- M
        ( 16#1F#, 16#02#, 16#04#, 16#08#, 16#1F# ),   -- N
        ( 16#0E#, 16#11#, 16#11#, 16#11#, 16#0E# ),   -- O
        ( 16#1F#, 16#05#, 16#05#, 16#05#, 16#02# ),   -- P
        ( 16#0E#, 16#11#, 16#11#, 16#19#, 16#2E# ),   -- Q
        ( 16#1F#, 16#05#, 16#05#, 16#05#, 16#1A# ),   -- R
        ( 16#06#, 16#15#, 16#15#, 16#15#, 16#08# ),   -- S
        ( 16#01#, 16#01#, 16#1F#, 16#01#, 16#01# ),   -- T
        ( 16#0F#, 16#10#, 16#10#, 16#10#, 16#0F# ),   -- U
        ( 16#07#, 16#08#, 16#10#, 16#08#, 16#07# ),   -- V
        ( 16#1F#, 16#10#, 16#0C#, 16#10#, 16#1F# ),   -- W
        ( 16#11#, 16#0A#, 16#04#, 16#0A#, 16#11# ),   -- X
        ( 16#01#, 16#02#, 16#1C#, 16#02#, 16#01# ),   -- Y
        ( 16#11#, 16#19#, 16#15#, 16#13#, 16#11# ),   -- Z
        ( 16#00#, 16#1F#, 16#11#, 16#11#, 16#00# ),   -- [
        ( 16#01#, 16#02#, 16#04#, 16#08#, 16#10# ),   -- \
        ( 16#00#, 16#11#, 16#11#, 16#1F#, 16#00# ),   -- ]
        ( 16#04#, 16#02#, 16#01#, 16#02#, 16#04# ),   -- ^
        ( 16#10#, 16#10#, 16#10#, 16#10#, 16#10# ),   -- _

        ( 16#00#, 16#01#, 16#02#, 16#04#, 16#00# ),   -- `
        ( 16#08#, 16#14#, 16#14#, 16#1C#, 16#10# ),   -- a
        ( 16#1F#, 16#14#, 16#14#, 16#14#, 16#08# ),   -- b
        ( 16#0C#, 16#12#, 16#12#, 16#12#, 16#04# ),   -- c
        ( 16#08#, 16#14#, 16#14#, 16#14#, 16#1F# ),   -- d
        ( 16#1C#, 16#2A#, 16#2A#, 16#2A#, 16#0C# ),   -- e
        ( 16#00#, 16#08#, 16#3E#, 16#09#, 16#02# ),   -- f
        ( 16#48#, 16#94#, 16#94#, 16#94#, 16#68# ),   -- g
        ( 16#1F#, 16#08#, 16#04#, 16#04#, 16#18# ),   -- h
        ( 16#00#, 16#10#, 16#1D#, 16#10#, 16#00# ),   -- i
        ( 16#20#, 16#40#, 16#3D#, 16#00#, 16#00# ),   -- j
        ( 16#1F#, 16#04#, 16#0A#, 16#10#, 16#00# ),   -- k
        ( 16#00#, 16#01#, 16#3E#, 16#20#, 16#00# ),   -- l
        ( 16#1C#, 16#04#, 16#18#, 16#04#, 16#1C# ),   -- m
        ( 16#1C#, 16#08#, 16#04#, 16#04#, 16#18# ),   -- n
        ( 16#08#, 16#14#, 16#14#, 16#14#, 16#08# ),   -- o
        ( 16#FC#, 16#14#, 16#14#, 16#14#, 16#08# ),   -- p
        ( 16#08#, 16#14#, 16#14#, 16#FC#, 16#40# ),   -- q
        ( 16#1C#, 16#08#, 16#04#, 16#04#, 16#08# ),   -- r
        ( 16#10#, 16#24#, 16#2A#, 16#2A#, 16#10# ),   -- s
        ( 16#00#, 16#04#, 16#1F#, 16#24#, 16#00# ),   -- t
        ( 16#0C#, 16#10#, 16#10#, 16#10#, 16#0C# ),   -- u
        ( 16#04#, 16#08#, 16#10#, 16#08#, 16#04# ),   -- v
        ( 16#1C#, 16#10#, 16#0C#, 16#10#, 16#1C# ),   -- w
        ( 16#14#, 16#08#, 16#08#, 16#08#, 16#14# ),   -- x
        ( 16#4C#, 16#90#, 16#90#, 16#90#, 16#7C# ),   -- y
        ( 16#24#, 16#34#, 16#2C#, 16#24#, 16#00# ),   -- z
        ( 16#00#, 16#04#, 16#1B#, 16#11#, 16#00# ),   -- {
        ( 16#00#, 16#00#, 16#7F#, 16#00#, 16#00# ),   -- |
        ( 16#00#, 16#11#, 16#1B#, 16#04#, 16#00# ),   -- }
        ( 16#04#, 16#02#, 16#04#, 16#08#, 16#04# ),   -- ~
        ( 16#7F#, 16#7F#, 16#7F#, 16#7F#, 16#7F# )    -- DEL
    );

    ------------------------------------------------------------------
    -- Controller Access Modes
    ------------------------------------------------------------------

    type Enable_Type is (
        Unselect,           -- PCD8544 Chip unselected (disabled)
        Command_Mode,       -- /CE and in Command I/O mode
        Data_Mode           -- /CE and in Data I/O mode
    );

    ------------------------------------------------------------------
    -- Internal - Enable/Disable device 
    ------------------------------------------------------------------
    procedure Set_Mode(Context : IO_Context; Enable : Enable_Type) is
    begin
        case Enable is
            when Unselect =>
                Context.IO_Proc(CE,True);           -- Disable /CE
            when Command_Mode =>
                Context.IO_Proc(CE,False);          -- Enable /CE
                Context.IO_Proc(DataCmd,False);     -- /Command Mode
            when Data_Mode =>
                Context.IO_Proc(CE,False);          -- Enable /CE
                Context.IO_Proc(DataCmd,True);      -- +Data Mode
        end case;
    end Set_Mode;

    ------------------------------------------------------------------
    -- Internal - Write one data/command bit to LCD controller
    ------------------------------------------------------------------
    procedure Write(Context : IO_Context; Bit : Boolean) is
    begin
        Context.IO_Proc(DataIn,Bit);    -- Set state of data bit
        Context.IO_Proc(Clock,True);    -- This clocks the data
        Context.IO_Proc(Clock,False);   -- Return to low state to idle
    end Write;

    ------------------------------------------------------------------
    -- Internal - Write one data/command byte to LCD controller
    ------------------------------------------------------------------
    procedure Write(Context : IO_Context; Byte : Unsigned_8) is
        Mask : Unsigned_8 := 16#80#;
    begin
        while Mask /= 0 loop
            Write(Context,(Mask and Byte) /= 0);
            Mask := Shift_Right(Mask,1);
        end loop;
    end Write;

    ------------------------------------------------------------------
    -- API - Initialize the LCD Controller
    ------------------------------------------------------------------
    procedure Initialize(
        Context :       in out  IO_Context;
        IO_Proc :       in      Set_IO_Proc;
        Contrast :      in      Vop_Type  := 16#5F#;
        Temp_Coef :     in      TC_Type   := 0;
        Bias :          in      Bias_Type := 4
    ) is
    begin

        Context.IO_Proc     := IO_Proc;
        Context.Contrast    := Contrast;
        Context.Temp_Coef   := Temp_Coef;
        Context.Bias        := Bias;

        -- Establish all pin signals high
        -- This makes /RESET and /CE inactive

        for Pin in CE..Clock loop
            Context.IO_Proc(Pin,True);  -- Set pin to the high state
        end loop;

        Context.IO_Proc(Clock,False);   -- Idle clock line at low
        Context.IO_Proc(Reset,False);   -- Apply /RESET
        Context.IO_Proc(Reset,True);    -- Remove /RESET        
        Context.IO_Proc(DataCmd,True);  -- Waste a little time to allow reset

        Set_Mode(Context,Command_Mode);

        declare
            Set_Vop :   Unsigned_8 := Unsigned_8(Context.Contrast) or 16#80#;
            Set_TC :    Unsigned_8 := Unsigned_8(Context.Temp_Coef) or 16#04#;
            Set_Bias :  Unsigned_8 := Unsigned_8(Context.Bias) or 16#10#;
        begin
            Write(Context,16#21#);      -- Enable extended instruction set
            Write(Context,Set_Vop);     -- Set contrast
            Write(Context,Set_TC);      -- Set temperature coefficient
            Write(Context,Set_Bias);    -- Set controller bias
            Write(Context,16#20#);      -- Disable extended instruction set
            Write(Context,16#0C#);      -- Set normal display mode
        end;

        Set_Mode(Context,Unselect);

        Context.X           := 0;
        Context.Y           := 0;
        
        Context.Buffer      := ( ( ' ', others => ' ' ), others => ( ' ', others => ' ' ) );

    end Initialize;

    ------------------------------------------------------------------
    -- Home Cursor
    ------------------------------------------------------------------
    procedure Home(Context : in out IO_Context) is
    begin
        Move(Context,0,0);
    end Home;

    ------------------------------------------------------------------
    -- Establish a new Y Coordinate 
    ------------------------------------------------------------------
    procedure Set_Y(Context : in out IO_Context; Y : Y_Coord) is
        Set_Y_Cmd : Unsigned_8 := Unsigned_8(Y) or 16#40#;
    begin
        Set_Mode(Context,Command_Mode);
        Write(Context,Set_Y_Cmd);
        Set_Mode(Context,Unselect);
        Context.Y := Y;
    end Set_Y;

    ------------------------------------------------------------------
    -- Establish a new X Coordinate
    ------------------------------------------------------------------
    procedure Set_X(Context : in out IO_Context; X : X_Coord) is
        Set_X_Cmd : Unsigned_8 := Unsigned_8(X) or 16#80#;
    begin
        Set_Mode(Context,Command_Mode);
        Write(Context,Set_X_Cmd);
        Set_Mode(Context,Unselect);
        Context.X := X;
    end Set_X;

    ------------------------------------------------------------------
    -- Establish a new Y and X Coordinate
    ------------------------------------------------------------------
    procedure Move(Context : in out IO_Context; Y : Y_Coord; X : X_Coord) is
        Set_Y_Cmd : Unsigned_8 := Unsigned_8(Y) or 16#40#;
        Set_X_Cmd : Unsigned_8 := Unsigned_8(X) or 16#80#;
    begin
        Set_Mode(Context,Command_Mode);
        Write(Context,Set_Y_Cmd);
        Write(Context,Set_X_Cmd);
        Set_Mode(Context,Unselect);
        Context.Y := Y;
        Context.X := X;
    end Move;

    ------------------------------------------------------------------
    -- Clear screen and home cursor
    ------------------------------------------------------------------
    procedure Clear(Context : in out IO_Context) is
    begin
        Home(Context);
        Clear_to_Bot(Context);
    end Clear;

    ------------------------------------------------------------------
    -- Clear from current position to end of screen
    ------------------------------------------------------------------
    procedure Clear_to_Bot(Context : in out IO_Context) is
        Start_X : X_Coord := Context.X;
    begin

        Move(Context,Context.Y,Context.X);
        Set_Mode(Context,Data_Mode);

        for Y in Context.Y..Y_Coord'Last loop
            for X in Start_X..X_Coord'Last loop 
                for B in 1..6 loop
                    Write(Context,16#00#);  -- blank out 6 x pixels for each char
                end loop;
                Context.Buffer(Y,X) := ' '; -- Blank out char in buffer
            end loop;
            Start_X := X_Coord'First;
        end loop;

        Set_Mode(Context,Unselect);
        Move(Context,Context.Y,Context.X);  -- Restore LCD cursor position

    end Clear_to_Bot;

    ------------------------------------------------------------------
    -- Clear to end of current line
    ------------------------------------------------------------------

    procedure Clear_to_End(Context : in out IO_Context) is
    begin

        Move(Context,Context.Y,Context.X);
        Set_Mode(Context,Data_Mode);

        for X in Context.X..X_Coord'Last loop 
            for B in 1..6 loop
                Write(Context,16#00#);  -- blank out 6 x pixels for each char
            end loop;
            Context.Buffer(Context.Y,X) := ' ';
        end loop;

        Set_Mode(Context,Unselect);
        Move(Context,Context.Y,Context.X);

    end Clear_to_End;

    ------------------------------------------------------------------
    -- Return current Y coordinate
    ------------------------------------------------------------------
    function Y(Context : IO_Context) return Y_Coord is
    begin
        return Context.Y;
    end Y;

    ------------------------------------------------------------------
    -- Return current X coordinate
    ------------------------------------------------------------------
    function X(Context : IO_Context) return X_Coord is
    begin
        return Context.X;
    end X;

    ------------------------------------------------------------------
    -- Internal - Calculate the Pixmap Index for a character
    ------------------------------------------------------------------
    function Font_Char(Char : Character) return Pixel_Row is
        Ch : Character := Char;
    begin

        if Char < ' ' or else Character'Pos(Char) > 16#7F# then
            Ch := ' ';  -- Treat as a blank
        end if;

        return Pixel_Row(Character'Pos(Ch) - 16#20#);

    end Font_Char;

    ------------------------------------------------------------------
    -- Internal - Put raw character to LCD
    ------------------------------------------------------------------
    procedure Put_Raw(Context : in out IO_Context; Char : Character) is
        Font_X : Pixel_Row := Font_Char(char);     -- Lookup font bitmap
    begin

        Set_Mode(Context,Data_Mode);
        for Pixel in Pixel_Width'Range loop
            Write(Context,Font(Font_X,Pixel));
        end loop;
        Write(Context,16#00#);                  -- 1 blank pixel after char
        Set_Mode(Context,Unselect);

    end Put_Raw;

    ------------------------------------------------------------------
    -- Internal - Scroll LCD up one line
    ------------------------------------------------------------------
    procedure Scroll(Context : in out IO_Context) is
        Save_Y : Y_Coord := Context.Y;
        Save_X : X_Coord := Context.X;
    begin

        Home(Context);

        for Y in Y_Coord'First .. Y_Coord'Last loop
            for X in X_Coord'Range loop
                if Y < Y_Coord'Last then
                    Context.Buffer(Y,X) := Context.Buffer(Y+1,X);
                    Put_Raw(Context,Context.Buffer(Y,X));
                else
                    Context.Buffer(Y_Coord'Last,X) := ' ';
                    Put_Raw(Context,' ');
                end if;
            end loop;
        end loop;

        Move(Context,Save_Y,Save_X);      -- Restore cursor

    end Scroll;

    ------------------------------------------------------------------
    -- Put character to LCD
    ------------------------------------------------------------------
    procedure Put(Context : in out IO_Context; Ch : Character) is
        use Ada.Characters.Latin_1;
    begin

        if Ch = CR then
            Set_X(Context,0);
            return;
        end if;

        if Ch = LF then
            if Context.Y >= Y_Coord'Last then
                Scroll(Context);
                Move(Context,Y_Coord'Last,X_Coord'First);
            else
                Move(Context,Context.Y+1,X_Coord'First);
            end if;
            return;
        end if;

        if Context.X >= X_Coord'Last then
            if Context.Y >= Y_Coord'Last then
                Scroll(Context);
                Move(Context,Y_Coord'Last,X_Coord'First);
            else
                Move(Context,Context.Y+1,X_Coord'First);
            end if;
        end if;

        if Ch = NUL then
            return;                     -- NUL just causes Y,X to be fixed when X at end of line
        end if;

        Put_Raw(Context,Ch);
        Context.Buffer(Context.Y,Context.X) := Ch;

        Context.X := Context.X + 1;

    end Put;

    ------------------------------------------------------------------
    -- Put a String of characters to the LCD
    ------------------------------------------------------------------
    procedure Put(Context : in out IO_Context; Text : String) is
    begin

        for X in Text'Range loop
            Put(Context,Text(X));
        end loop;

    end Put;

end pcd8544;
