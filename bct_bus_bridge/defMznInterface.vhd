library ieee, mylib;
use ieee.std_logic_1164.all;

package defMIF is
  -- Status --
  constant kWidthStatusMzn       : integer:= 2;
  constant kWidthStatusBase      : integer:= 4;

  -- Mezzanine to Base --
  constant kIdMznInThrottlingT2  : integer:= 0;
  constant kIdMznThrottlingAll   : integer:= 1;

  -- Base to Mezzanine --
  constant kIdBaseProgFullBMgr   : integer:= 0;
  constant kIdBaseHbfNumMismatch : integer:= 1;
  constant kIdBaseTcpActive      : integer:= 2;
  constant kIdBaseEmptyLinkBuf   : integer:= 3;

end package defMIF;
