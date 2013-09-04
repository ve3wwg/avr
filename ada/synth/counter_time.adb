-- counter_time.adb - Wed Aug 25 10:46:42 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id: counter_time.adb,v 1.1 2010-08-27 03:30:44 Warren Gray Exp $
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

package body Counter_Time is

    ------------------------------------------------------------------
    -- Return Time Difference, taking into account Counter Wrap Around
    ------------------------------------------------------------------
    function Delta_Time(Time0, Time1 : Unsigned_32; Max_Time : Unsigned_32 := Max_Time_Default)
        return Integer_32 is

        Time_Delta :    Unsigned_32;
    begin

        if Time0 = Time1 then
            return 0;
        elsif Time0 < Time1 then
            Time_Delta := Time1 - Time0;
            if Time_Delta < Max_Time then
                return Integer_32(Time_Delta);    -- Time0 < Time1
            else
                return -Integer_32((Unsigned_32'Last - Time1) + 1 + Time0);
            end if;
        else
            Time_Delta := Time0 - Time1;
            if Time_Delta < Max_Time then
                return -Integer_32(Time_Delta);     -- Time0 > Time1
            else
                return Integer_32(Unsigned_32'Last - Time0 + 1 + Time1);
            end if;
        end if;

    end Delta_Time;

end Counter_Time;
