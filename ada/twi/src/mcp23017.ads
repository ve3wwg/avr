-- mcp23017.ads - Wed Sep 25 18:34:48 2013
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- MCP23017 I2C Driver
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

with Ada.Unchecked_Conversion;

with Interfaces;
use  Interfaces;

with AVR;
with TWI;

package MCP23017 is

    type Error_Code is (
        No_Error,
        TWI_Error
    );

    subtype Bit_Number      is AVR.Bit_Number;
    subtype Bits_In_Byte    is AVR.Bits_In_Byte;
    subtype Nat8            is AVR.Nat8;
    
    function "+" is
        new Ada.Unchecked_Conversion(Source => Bits_In_Byte,
                                     Target => Nat8);
        
    function "+" is
        new Ada.Unchecked_Conversion(Source => Nat8,
                                     Target => Bits_In_Byte);
                                                                                          
    subtype Slave_Addr      is TWI.Slave_Addr;

    DD_Inputs :             constant := 2#1111_1111#;
    DD_Outputs :            constant := 2#0000_0000#;

    type Port_Type is ( Port_A, Port_B );

    procedure Initialize(Addr : Slave_Addr; Error : out Error_Code; Slew : Boolean := true);
    procedure Set_Direction(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code);
    procedure Get_Direction(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code);

    -- Get/Set Pullup resistor settings
    procedure Set_Pullup(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code);
    procedure Get_Pullup(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code);

    -- Get/Set Input polarity
    procedure Get_Polarity(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code);
    procedure Set_Polarity(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code);

    -- Get/Set Latches:
    procedure Get_Latch(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code);
    procedure Set_Latch(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code);

    -- Write GPIO
    procedure Write(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code);
    procedure Write(Addr : Slave_Addr; Port : Port_Type; Data : Nat8; Error : out Error_Code);
    procedure Write(Addr : Slave_Addr; Port : Port_Type; Bit : Bit_Number; Data : Boolean; Error : out Error_Code);

    -- Read GPIO
    procedure Read(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code);
    procedure Read(Addr : Slave_Addr; Port : Port_Type; Data : out Nat8; Error : out Error_Code);
    procedure Read(Addr : Slave_Addr; Port : Port_Type; Bit : Bit_Number; Data : out Boolean; Error : out Error_Code);

    ------------------------------------------------------------------
    -- Set Interrupt on Change:
    ------------------------------------------------------------------
    -- Enable:  Each 1-bit enables interrupt participation
    -- Value:   Each bit is compared if Control bit=1
    -- Control: Each 1-bit says compare I/O bit with Value bit
    --          Each 0-bit says just interrupt if changed from prior value
    ------------------------------------------------------------------
    procedure Set_Int_Change(Addr : Slave_Addr; Port : Port_Type; Enable, Value, Control : Nat8; Error : out Error_Code);
    procedure Get_Int_Change(Addr : Slave_Addr; Port : Port_Type; Enable, Value, Control : out Nat8; Error : out Error_Code);

    procedure Get_Int_Flags(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code);
    procedure Get_Int_Capture(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code);

    ------------------------------------------------------------------
    -- Configure/Query Interrupt Facility
    ------------------------------------------------------------------
    procedure Set_Mirror(Addr : Slave_Addr; Mirror : Boolean; Error : out Error_Code);
    procedure Get_Mirror(Addr : Slave_Addr; Mirror : out Boolean; Error : out Error_Code);
    procedure Set_Open_Drain(Addr : Slave_Addr; Open_Drain : Boolean; Error : out Error_Code);
    procedure Get_Open_Drain(Addr : Slave_Addr; Open_Drain : out Boolean; Error : out Error_Code);
    procedure Set_Int_Polarity(Addr : Slave_Addr; Active_High : Boolean; Error : out Error_Code);
    procedure Get_Int_Polarity(Addr : Slave_Addr; Active_High : out Boolean; Error : out Error_Code);

    
end MCP23017;
