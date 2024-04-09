library ieee, mylib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use mylib.defBCT.all;

package defBctBridge is
  -- Frame structure --
  -- MSB [8-bit command][<16-bit address][8-bit data] LSB --
  constant kWidthBctData    : integer:= 32;
  constant kNbytePayload    : integer:= kWidthBctData/8;
  constant kComWrite        : std_logic_vector(7 downto 0):= X"10";
  constant kComRead         : std_logic_vector(7 downto 0):= X"20";
  constant kComAck          : std_logic_vector(7 downto 0):= X"30";

  -- Primary -----------------------------------------------
  type BridgeIfProcessType is (
    Idle, StartIF, WaitSpiDone, Wait2ndryReq, Finalize
    );

  -- Local bus FSM for primary--
  type BBPBusProcessType is (
    Init, Idle, Connect,
    Write, Read,
    Execute,
    WaitDone,
    Finalize,
    Done
    );

  -- Local Address  --
  constant kTxd             : LocalAddressType := x"000"; -- W,   [31:0]
  constant kRxd             : LocalAddressType := x"010"; -- R,   [31:0]
  constant kExec            : LocalAddressType := x"100"; -- W,



  -- Secondary ---------------------------------------------
  constant kWidthAckSr      : integer:= 16;
  subtype  BctBridgeAddrType is std_logic_vector(15 downto 0);


end package defBctBridge;

