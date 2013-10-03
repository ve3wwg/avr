-- testio.adb - Thu Sep  5 22:41:48 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- IO Support for TestMain.adb
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;
with AVR.MCU;
with AVR.Wait;

-- with AVR.UART;
with AVR.Strings;

use AVR.Strings;
use Interfaces;

with TWI;

package body Test_IO is

    Count :             Unsigned_8 := 0;

    procedure My_Idle is
    begin
        Count := Count + 1;
    end My_Idle;

    My_Data : TWI.Data_Array := ( 16#00#, 16#01#, 16#02#, 16#03#, 16#04# );
    My_Reg :  Unsigned_16    := My_Data'First;

    procedure My_Transmitter(Count : Natural; Byte : out Unsigned_8; Ack : in out Boolean) is
    begin

        if My_Reg > My_Data'Last then
            My_Reg := My_Data'First;
        end if;
        Byte := My_Data(My_Reg);
        My_Reg := My_Reg + 1;

    end My_Transmitter;

    procedure My_Receiver(Count : Natural; Gen_Call : Boolean; Byte : Unsigned_8; Ack : in out Boolean) is
    begin

        if Count = 0 then
            My_Reg := Unsigned_16(Byte);
        else
            My_Data(My_Reg) := Byte;
            My_Reg := My_Reg + 1;
            if My_Reg > My_Data'Last then
                My_Reg := My_Data'First;
            end if;
        end if;

    end My_Receiver;

    procedure My_EOT(Count : Natural; Receiving : Boolean; Exit_Req : in out Boolean) is
    begin
        null;
    end My_EOT;

    procedure Test is
        PX, D : Unsigned_8;
    begin

        TWI.Set_Idle_Proc(My_Idle'Access);
        TWI.Divisors(16_000_000,400_000,PX,D);
        TWI.Initialize(16#10#,0,PX,D);
        TWI.Allow_Slave(My_Receiver'Access,My_Transmitter'Access,My_EOT'Access);
        TWI.Slave;
        TWI.Disable_Slave;

        loop
            null;
        end loop;

    end Test;

end Test_IO;
