library ieee, mylib;
use ieee.std_logic_1164.all;

package defMIF is
  -- Status --
  constant kWidthStatusMzn       : integer:= 1;
  constant kWidthStatusBase      : integer:= 5;

  -- Mezzanine to Base --
  constant kIdMznRecoveryRst     : integer:= 0;

  -- Base to Mezzanine --
  constant kIdBaseProgFullBMgr   : integer:= 0;
  constant kIdBaseHbfNumMismatch : integer:= 1;
  constant kIdBaseTcpActive      : integer:= 2;
  constant kIdBaseEmptyLinkBuf   : integer:= 3;
  constant kIdBaseOutThrottling  : integer:= 4;

end package defMIF;
