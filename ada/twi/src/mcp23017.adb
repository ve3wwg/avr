-- mcp23017.adb - Wed Sep 25 19:05:05 2013
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- MCP23017 I2C Driver
--
-- Protected under the GNU GENERAL PUBLIC LICENSE v2, June 1991

package body MCP23017 is

    IOCON :     constant := 16#0A#;
    IODIRA :    constant := 16#00#;
    IODIRB :    constant := 16#01#;
    GPIOA :     constant := 16#12#;
    GPIOB :     constant := 16#13#;

    IODIR_CFG : constant Unsigned_8 := 16#00#;  -- Outputs


    IO_Buf :    aliased TWI.Data_Array := (
                        IOCON,  2#0000_0000#,   -- 0..1     Msg_Init: I/O Config
                        IODIRA, 0,      0,      -- 2..4     Set_Dir:  Set direction of A & B
                        GPIOA,  0,      0,      -- 5..7     Write_Both: Write Ports A & B
                        GPIOB,  0,              -- 8..9     Write_B : Write B alone
                        0
                );

    Dir_A :     Unsigned_8 renames IO_Buf(3);
    Dir_B :     Unsigned_8 renames IO_Buf(4);
    Prt_A :     Unsigned_8 renames IO_BUF(6);
    Prt_B :     Unsigned_8 renames IO_BUF(7);
    Prt_B1 :    Unsigned_8 renames IO_Buf(9);

    Msg_Init :  aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 0, Last => 1 )
                );

    Set_Dir :   aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 2, Last => 4 )
                );
    
    Get_Dir :   aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 2, Last => 2 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 3, Last => 4 )
                );

    Write_AB :  aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 5, Last => 7 )
                );

    Wr_A :      aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 5, Last => 6 )
                );

    Wr_B :      aliased TWI.Xfer_Array := (
                    0 => ( Addr => 0, Xfer => TWI.Write, First => 8, Last => 9 )
                );
    
    Rd_AB :     aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 5, Last => 5 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 6, Last => 7 )
                );

    Rd_A :      aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 5, Last => 5 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 6, Last => 6 )
                );

    Rd_B :      aliased TWI.Xfer_Array := (
                    ( Addr => 0, Xfer => TWI.Write, First => 8, Last => 8 ),
                    ( Addr => 0, Xfer => TWI.Read,  First => 7, Last => 7 ) -- aka Prt_B
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
    procedure Initialize(Addr : Slave_Addr; Error : out Error_Code) is
    begin
        Xfer(Addr,Msg_Init'Access,Error);
    end Initialize;

    ------------------------------------------------------------------
    -- Configure A & B Ports for Input/Output (Input = 0)
    ------------------------------------------------------------------
    procedure Set_Direction(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code) is
    begin
        Dir_A := A;
        Dir_B := B;
        Xfer(Addr,Set_Dir'Access,Error);
    end Set_Direction;

    ------------------------------------------------------------------
    -- Read Configuration of A & B Ports
    ------------------------------------------------------------------
    procedure Get_Direction(Addr : Slave_Addr; A, B : out Nat8; Error : out Error_Code) is
    begin
        Xfer(Addr,Get_Dir'Access,Error);
        A := Dir_A;
        B := Dir_B;
    end Get_Direction;

    ------------------------------------------------------------------
    -- Write both GPIO A & B 
    ------------------------------------------------------------------
    procedure Write(Addr : Slave_Addr; A, B : Nat8; Error : out Error_Code) is
    begin
        Prt_A := A;
        Prt_B := B;
        Xfer(Addr,Write_AB'Access,Error);
    end Write;

    ------------------------------------------------------------------
    -- Write GPIO A Alone
    ------------------------------------------------------------------
    procedure Write(Addr : Slave_Addr; Port : Port_Type; Data : Nat8; Error : out Error_Code) is
    begin
        case Port is
            when Port_A =>
                Prt_A := Data;
                Xfer(Addr,Wr_A'Access,Error);
            when Port_B =>
                Prt_B1 := Data;
                Xfer(Addr,Wr_B'Access,Error);
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
        Xfer(Addr,Rd_AB'Access,Error);
        A := Prt_A;
        B := Prt_B;
    end Read;

    ------------------------------------------------------------------
    -- Read GPIOA or GPIOB
    ------------------------------------------------------------------
    procedure Read(Addr : Slave_Addr; Port : Port_Type; Data : out Nat8; Error : out Error_Code) is
    begin
        case Port is
            when Port_A =>
                Xfer(Addr,Rd_A'Access,Error);
                Data := Prt_A;
            when Port_B =>
                Xfer(Addr,Rd_B'Access,Error);
                Data := Prt_B;
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

end MCP23017;
