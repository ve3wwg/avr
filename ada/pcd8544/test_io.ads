-- testio.ads - Thu Sep  5 22:40:04 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- TestMain's IO Support
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with PCD8544;

package Test_IO is

    procedure Pin_IO(Pin : PCD8544.IO_Pin; State : Boolean);

    procedure Blinky;

end Test_IO;

