-- mcp23017.adb - Wed Sep 25 19:05:05 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- MCP23017 I2C Driver
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

package body MCP23017 is

    IODIRA :    constant := 16#00#;
    IODIRB :    constant := 16#01#;
    IPOLA :     constant := 16#02#;
    GPINTENA :  constant := 16#04#;
    GPINTENB :  constant := 16#05#;
    DEFVALA :   constant := 16#06#;
    DEFVALB :   constant := 16#07#;
    INTCONA :   constant := 16#08#;
    INTCONB :   constant := 16#09#;
    IOCON :     constant := 16#0A#;
    GPPUA :     constant := 16#0C#;
    GPPUB :     constant := 16#0D#;
    INTFA :     constant := 16#0E#;
    INTFB :     constant := 16#0F#;
    INTCAPA :   constant := 16#10#;
    INTCAPB :   constant := 16#11#;
    GPIOA :     constant := 16#12#;
    GPIOB :     constant := 16#13#;
    OLATA :     constant := 16#14#;
    OLATB :     constant := 16#15#;

    IODIR_CFG : constant Unsigned_8 := 16#00#;  -- Outputs


    IO_Buf :    aliased TWI.Data_Array := (
                        IOCON,  2#0000_0000#,   -- 0..1     Msg_Init: I/O Config
                        IODIRA, 0,      0,      -- 2..4     Write pair or single
                        GPIOA,  0,      0,      -- 5..7     Read pair or single
                        GPINTENA, 0,            -- 8..9     Set GPINTENA/B
                        DEFVALA,  0,            -- 10..11   Set DEFVALA/B
                        INTCONA,  0,            -- 12..13   Set INTCONA/B
                    0
                );

    IOCFG :     Unsigned_8 renames IO_Buf(1);
    Wr_R :      Unsigned_8 renames IO_Buf(2);
    Wr_A :      Unsigned_8 renames IO_Buf(3);
    Wr_B :      Unsigned_8 renames IO_Buf(4);

    Rd_R :      Unsigned_8 renames IO_Buf(5);
    Rd_A :      Unsigned_8 renames IO_Buf(6);
    Rd_B :      Unsigned_8 renames IO_Buf(7);

    INTCHG_R :  Unsigned_8 renames IO_BUF(8);
    INTEN :     Unsigned_8 renames IO_BUF(9);
    DEFVAL_R :  Unsigned_8 renames IO_BUF(10);
    DEFVAL :    Unsigned_8 renames IO_BUF(11);
    INTCON_R :  Unsigned_8 renames IO_BUF(12);
    INTCON :    Unsigned_8 renames IO_BUF(13);


    Msg_Init :  aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 0, Last => 1 )
                );

    Write_AB :  aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 2, Last => 4 )
                );

    Write_1 :   aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 2, Last => 3 )
                );

    Read_AB :   aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 5, Last => 5 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 6, Last => 7 )
                );

    Read_1 :    aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 5, Last => 5 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 6, Last => 6 )
                );

    Int_Msg :   aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 8, Last => 9 ),
                    ( Addr => 0, Xfer => TWI.Write, First => 10, Last => 11 ),
                    ( Addr => 0, Xfer => TWI.Write, First => 12, Last => 13 )
                );

    Get_Int :   aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 8,  Last => 8 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 9,  Last => 9 ),
                    ( Addr => 0, Xfer => TWI.Write, First => 10, Last => 10 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 11, Last => 11 ),
                    ( Addr => 0, Xfer => TWI.Write, First => 12, Last => 12 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 13, Last => 13 )
                );

    ------------------------------------------------------------------
    -- Internal : Perform an I2C Transfer
    ------------------------------------------------------------------
    procedure Xfer(Addr : TWI.Slave_Addr; Xfer_Msg : TWI.Xfer_Array_Ptr; Error : out Error_Code) is
        use TWI;

        I2C_Error : TWI.Error_Code;
    begin
        for X in Xfer_Msg'Range loop
            Xfer_Msg(X).Addr := Addr;
        end loop;

        Master(Xfer_Msg,IO_Buf'Access,I2C_Error);

        if I2C_Error /= TWI.No_Error then
            Error := TWI_Error;
        else
            TWI.Complete(I2C_Error,true);
            if I2C_Error /= TWI.No_Error then
                Error := TWI_Error;
            else
                Error := No_Error;
            end if;
        end if;
    end Xfer;

    ------------------------------------------------------------------
    -- Initialize the MCP23017 for I/O with this driver
    ------------------------------------------------------------------
    procedure Initialize(Addr : Slave_Addr; Error : out Error_Code; Slew : Boolean := true) is
    begin
        if Slew then
            IOCFG := 2#0000_0000#;      -- SDA Slew enabled
        else
            IOCFG := 2#0001_0000#;      -- SDA Slew disabled
        end if;

        Xfer(Addr,Msg_Init'Access,Error);
    end Initialize;

    ------------------------------------------------------------------
    -- Internal : Put Pair of Registers
    ------------------------------------------------------------------
    procedure Put_Pair(Addr : Slave_Addr; R, A, B : Nat8; Error : out Error_Code) is
    begin
        Wr_R := R;     -- MCP23017 Register
        Wr_A := A;
        Wr_B := B;
        Xfer(Addr,Write_AB'Access,Error);
    end Put_Pair;

    ------------------------------------------------------------------
    -- Internal : Put a Single Byte to a Register
    ------------------------------------------------------------------
    procedure Put_Single(Addr : Slave_Addr; R, A : Nat8; Error : out Error_Code) is
    begin
        Wr_R := R;     -- MCP23017 Register
        Wr_A := A;
        Xfer(Addr,Write_1'Access,Error);
    end Put_Single;

    ------------------------------------------------------------------
    -- Internal : Read A & B Pair
    ------------------------------------------------------------------
    procedure Get_Pair(Addr : Slave_Addr; R : Nat8; A, B : out Nat8; Error : out Error_Code) is
    begin
        Rd_R := R;
        Xfer(Addr,Read_AB'Access,Error);
        A := Rd_A;
        B := Rd_B;
    end Get_Pair;

    ------------------------------------------------------------------
    -- Internal : Get a Single Byte from Register
    ------------------------------------------------------------------
    procedure Get_Single(Addr : Slave_Addr; R : Nat8; A : out Nat8; Error : out Error_Code) is
    begin
        Rd_R := R;
        Xfer(Addr,Read_1'Access,Error);
        A := Rd_A;
    end Get_Single;

    ------------------------------------------------------------------
    -- Configure A & B Ports for Input/Output (Input = 0)
    ------------------------------------------------------------------
    procedure Set_Direction(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code) is
    begin
        Put_Pair(Addr,IODIRA,A,B,Error);
    end Set_Direction;

    ------------------------------------------------------------------
    -- Read Configuration of A & B Ports
    ------------------------------------------------------------------
    procedure Get_Direction(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Get_Pair(Addr,IODIRA,A,B,Error);
    end Get_Direction;

    ------------------------------------------------------------------
    -- Write both GPIO A & B 
    ------------------------------------------------------------------
    procedure Write(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code) is
    begin
        Put_Pair(Addr,GPIOA,A,B,Error);
    end Write;

    ------------------------------------------------------------------
    -- Write GPIO A Alone
    ------------------------------------------------------------------
    procedure Write(Addr : Slave_Addr; Port : Port_Type; Data : Nat8; Error : out Error_Code) is
    begin
        case Port is
            when Port_A =>
                Put_Single(Addr,GPIOA,Data,Error);
            when Port_B =>
                Put_Single(Addr,GPIOB,Data,Error);
        end case;
            
    end Write;

    ------------------------------------------------------------------
    -- Write Bit 0..7 in GPIOA or GPIOB
    ------------------------------------------------------------------
    procedure Write(Addr : Slave_Addr; Port : Port_Type; Bit : Bit_Number; Data : Boolean; Error : out Error_Code) is
        Byte : Nat8;
        Bits : Bits_In_Byte;
    begin
        Read(Addr,Port,Byte,Error);
        if Error = No_Error then
            Bits := +Byte;
            Bits(Bit) := Data;
            Byte := +Bits;
            Write(Addr,Port,Byte,Error);
        end if;
    end Write;

    ------------------------------------------------------------------
    -- Read both A & B Ports
    ------------------------------------------------------------------
    procedure Read(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Get_Pair(Addr,GPIOA,A,B,Error);
    end Read;

    ------------------------------------------------------------------
    -- Read GPIOA or GPIOB
    ------------------------------------------------------------------
    procedure Read(Addr : Slave_Addr; Port : Port_Type; Data : out Nat8; Error : out Error_Code) is
    begin
        case Port is
            when Port_A =>
                Get_Single(Addr,GPIOA,Data,Error);
            when Port_B =>
                Get_Single(Addr,GPIOB,Data,Error);
        end case;
    end Read;

    ------------------------------------------------------------------
    -- Read bit 0..7 in GPIOA or GPIOB
    ------------------------------------------------------------------
    procedure Read(Addr : Slave_Addr; Port : Port_Type; Bit : Bit_Number; Data : out Boolean; Error : out Error_Code) is
        Byte : Nat8;
        Bits : Bits_In_Byte;
    begin
        Read(Addr,Port,Byte,Error);
        if Error = No_Error then
            Bits := +Byte;
            Data := Bits(Bit);
        end if;
    end Read;

    ------------------------------------------------------------------
    -- Set/Get Polarity of GPIOA/B
    ------------------------------------------------------------------
    procedure Set_Polarity(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code) is
    begin
        Put_Pair(Addr,IPOLA,A,B,Error);
    end Set_Polarity;
    
    procedure Get_Polarity(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Get_Pair(Addr,IPOLA,A,B,Error);
    end Get_Polarity;

    ------------------------------------------------------------------
    -- Set/Get Interrupt on Change Registers
    ------------------------------------------------------------------

    procedure Set_Int_Change(Addr : Slave_Addr; Port : Port_Type; Enable, Value, Control : Nat8; Error : out Error_Code) is
    begin
        case Port is
            when Port_A =>
                INTCHG_R := GPINTENA;
                DEFVAL_R := DEFVALA;
                INTCON_R := INTCONA;
            when Port_B =>
                INTCHG_R := GPINTENB;
                DEFVAL_R := DEFVALB;
                INTCON_R := INTCONB;
        end case;

        INTEN    := Enable;
        DEFVAL   := Value;
        INTCON   := Control;

        Xfer(Addr,Int_Msg'Access,Error);

    end Set_Int_Change;

    procedure Get_Int_Change(Addr : Slave_Addr; Port : Port_Type; Enable, Value, Control : out Nat8; Error : out Error_Code) is
    begin
        case Port is
            when Port_A =>
                INTCHG_R := GPINTENA;
                DEFVAL_R := DEFVALA;
                INTCON_R := INTCONA;
            when Port_B =>
                INTCHG_R := GPINTENB;
                DEFVAL_R := DEFVALB;
                INTCON_R := INTCONB;
        end case;

        Xfer(Addr,Get_Int'Access,Error);

        Enable  := INTEN;
        Value   := DEFVAL;
        Control := INTCON;

    end Get_Int_Change;

    ------------------------------------------------------------------
    -- Configure/Query Interrupt Facility
    ------------------------------------------------------------------
    procedure Set_Mirror(Addr : Slave_Addr; Mirror : Boolean; Error : out Error_Code) is
        C : Nat8 := 0;
    begin
        Get_Single(Addr,IOCON,C,Error);
        if Error = No_Error then
            if Mirror then
                C := C or  2#0100_0000#;
            else
                C := C and 2#1011_1111#;
            end if;
            Put_Single(Addr,IOCON,C,Error);
        end if;
    end Set_Mirror;
    
    procedure Get_Mirror(Addr : Slave_Addr; Mirror : out Boolean; Error : out Error_Code) is
        C : Nat8 := 0;
    begin
        Get_Single(Addr,IOCON,C,Error);
        Mirror := (C and 2#0100_0000#) /= 0;
    end Get_Mirror;

    procedure Set_Open_Drain(Addr : Slave_Addr; Open_Drain : Boolean; Error : out Error_Code) is
        C : Nat8 := 0;
    begin
        Get_Single(Addr,IOCON,C,Error);
        if Error = No_Error then
            if Open_Drain then
                C := C or  2#0000_0100#;
            else
                C := C and 2#1111_1011#;
            end if;
            Put_Single(Addr,IOCON,C,Error);
        end if;
    end Set_Open_Drain;

    procedure Get_Open_Drain(Addr : Slave_Addr; Open_Drain : out Boolean; Error : out Error_Code) is
        C : Nat8 := 0;
    begin
        Get_Single(Addr,IOCON,C,Error);
        Open_Drain := (C and 2#0000_0100#) /= 0;
    end Get_Open_Drain;
    
    procedure Set_Int_Polarity(Addr : Slave_Addr; Active_High : Boolean; Error : out Error_Code) is
        C : Nat8 := 0;
    begin
        Get_Single(Addr,IOCON,C,Error);
        if Error = No_Error then
            if Active_High then
                C := C or  2#0000_0010#;
            else
                C := C and 2#1111_1101#;
            end if;
            Put_Single(Addr,IOCON,C,Error);
        end if;
    end Set_Int_Polarity;
    
    procedure Get_Int_Polarity(Addr : Slave_Addr; Active_High : out Boolean; Error : out Error_Code) is
        C : Nat8 := 0;
    begin
        Get_Single(Addr,IOCON,C,Error);
        Active_High := (C and 2#0000_0010#) /= 0;
    end Get_Int_Polarity;

    ------------------------------------------------------------------
    -- Get/Set Pullup resistor settings
    ------------------------------------------------------------------
    procedure Set_Pullup(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code) is
    begin
        Put_Pair(Addr,GPPUA,A,B,Error);
    end Set_Pullup;

    procedure Get_Pullup(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Get_Pair(Addr,GPPUA,A,B,Error);
    end Get_Pullup;

    ------------------------------------------------------------------
    -- Get Interrupt Flags
    ------------------------------------------------------------------
    procedure Get_Int_Flags(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Get_Pair(Addr,INTFA,A,B,Error);
    end Get_Int_Flags;

    ------------------------------------------------------------------
    -- Get Captured Values
    ------------------------------------------------------------------
    procedure Get_Int_Capture(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Get_Pair(Addr,INTCAPA,A,B,Error);
    end Get_Int_Capture;

    ------------------------------------------------------------------
    -- Set Output Latch (even if configured as Input)
    ------------------------------------------------------------------
    procedure Set_Latch(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code) is
    begin
        Put_Pair(Addr,OLATA,A,B,Error);
    end Set_Latch;

    ------------------------------------------------------------------
    -- Read the Output Latch
    ------------------------------------------------------------------
    procedure Get_Latch(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Get_Pair(Addr,OLATA,A,B,Error);
    end Get_Latch;

end MCP23017;
