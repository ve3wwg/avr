-- midi.adb - Thu Aug 12 19:30:22 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id: midi.adb,v 1.1 2010-08-25 01:09:15 Warren Gray Exp $
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;

package body MIDI is

    function Shift_Left(Value : Unsigned_8; Amount : Natural) return Unsigned_8 is
        use Interfaces;
    begin
        return Unsigned_8(Interfaces.Shift_Left(Interfaces.Unsigned_8(Value),Amount));
    end;

    function Shift_Right(Value : Unsigned_8; Amount : Natural) return Unsigned_8 is
        use Interfaces;
    begin
        return Unsigned_8(Interfaces.Shift_Right(Interfaces.Unsigned_8(Value),Amount));
    end;
    
    function Shift_Left(Value : Unsigned_16; Amount : Natural) return Unsigned_16 is
        use Interfaces;
    begin
        return Unsigned_16(Interfaces.Shift_Left(Interfaces.Unsigned_16(Value),Amount));
    end;

    function Shift_Right(Value : Unsigned_16; Amount : Natural) return Unsigned_16 is
        use Interfaces;
    begin
        return Unsigned_16(Interfaces.Shift_Right(Interfaces.Unsigned_16(Value),Amount));
    end;

    function Shift_Left(Value : Unsigned_32; Amount : Natural) return Unsigned_32 is
        use Interfaces;
    begin
        return Unsigned_32(Interfaces.Shift_Left(Interfaces.Unsigned_32(Value),Amount));
    end;

    function Shift_Right(Value : Unsigned_32; Amount : Natural) return Unsigned_32 is
        use Interfaces;
    begin
        return Unsigned_32(Interfaces.Shift_Right(Interfaces.Unsigned_32(Value),Amount));
    end;
    
    ------------------------------------------------------------------
    -- Initialize the MIDI Context
    ------------------------------------------------------------------
    procedure Initialize(
        Context :       in out  IO_Context;
        Receiver :      in      Read_Byte_Proc := null;
        Transmitter :   in      Write_Byte_Proc := null;
        Poll :          in      Poll_Byte_Proc := null
    ) is
    begin

        Context.Receive_Byte    := Receiver;
        Context.Transmit_Byte   := Transmitter;
        Context.Poll_Byte       := Poll;

    end Initialize;


    ------------------------------------------------------------------
    -- Compute the MIDI Baud Rate Divisor for 31250 Baud
    ------------------------------------------------------------------
    function MIDI_Baud_Rate_Divisor(CPU_Clock_Freq : Unsigned_32) return Unsigned_16 is
    begin
        return Unsigned_16( Shift_Right(CPU_Clock_Freq,4) / 31250 ) - 1;
    end;

end MIDI;
