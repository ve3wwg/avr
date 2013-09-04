-- counter_time.ads - Wed Aug 25 10:47:45 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id: counter_time.ads,v 1.1 2010-08-27 03:30:44 Warren Gray Exp $
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Interfaces;
use Interfaces;

package Counter_Time is

    Max_Time_Default :  constant := 2 ** 31 - 1;    -- 31 bits worth

    ------------------------------------------------------------------
    -- Return Time Difference, taking into account Counter Wrap Around
    --
    -- The value Max should be chosen to represent the maximum delta
    -- time returned. Any deltas exceeding this indicate that the
    -- counter has wrapped. This affects the final delta returned.
    ------------------------------------------------------------------

    function Delta_Time(Time0, Time1 : Unsigned_32; Max_Time : Unsigned_32 := Max_Time_Default)
        return Integer_32;

end Counter_Time;


