with PCD8544;
with Test_IO;

procedure TestMain is
    use PCD8544;

    Context :   IO_Context;
begin

    Initialize(Context,Test_IO.Pin_IO'Access);
    --           1
    -- 01234567890123 --
    --     Hello      --
    --   ATMEGA168    --
    --    from the    --
    --    PCD8544     --
    --   Library!!    --
    --                --
    --0123456789ABCDEF==

    Move(Context,0,4);
    Put(Context,"Hello");
    Move(Context,1,2);
    Put(Context,"ATmega168");
    Move(Context,2,3);
    Put(Context,"from the");
    Move(Context,3,3);
    Put(Context,"PCD8544");
    Move(Context,4,2);
    Put(Context,"Library!!");
    Move(Context,5,0);
    Put(Context,"0123456789ABCD");

    Test_IO.Blinky;

end TestMain;
