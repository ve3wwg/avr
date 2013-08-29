-- with Interfaces;           use Interfaces;

with MIDI.Receiver;
with MIDI.Transmitter;

procedure MIDI_Test is
    IO :    MIDI.IO_Context;
begin

    MIDI.Initialize(IO);        -- This is missing I/O routines (don't run)

end MIDI_Test;
