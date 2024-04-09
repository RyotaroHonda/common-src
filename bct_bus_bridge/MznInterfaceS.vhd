library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library mylib;
use mylib.defMIF.all;

entity MznInterfaceS is
  port
    (
      -- toplevel ports -----------------------------------------------
      -- system ports --
      FRST_P            : in std_logic;
      FRST_N            : in std_logic;
      CLKHUL_P          : in std_logic;
      CLKHUL_N          : in std_logic;
      SLOT_POS_P        : in std_logic;
      SLOT_POS_N        : in std_logic;

      -- Bct Bus Bridge --
      BBS_PRI_ACTIVE_P  : in std_logic;
      BBS_PRI_ACTIVE_N  : in std_logic;
      BBS_SCN_REQ_P     : out std_logic;
      BBS_SCN_REQ_N     : out std_logic;
      BBS_CLK_P         : in std_logic;
      BBS_CLK_N         : in std_logic;
      BBS_POSI_P        : in std_logic;
      BBS_POSI_N        : in std_logic;
      BBS_PISO_P        : out std_logic;
      BBS_PISO_N        : out std_logic;


      -- status --
      STATUS_MZN_P      : out std_logic_vector(kWidthStatusMzn-1 downto 0);
      STATUS_MZN_N      : out std_logic_vector(kWidthStatusMzn-1 downto 0);
      STATUS_BASE_P     : in std_logic_vector(kWidthStatusBase-1 downto 0);
      STATUS_BASE_N     : in std_logic_vector(kWidthStatusBase-1 downto 0);

      -- Internal signals ---------------------------------------------
      -- System ports --
      forceReset        : out std_logic;
      clkHul            : out std_logic;
      slotPosition      : out std_logic;

      -- Bct Bus Bridge --
      bbsPrimActive     : out std_logic;
      bbsScndReq        : in std_logic;
      bbsClk            : out std_logic;
      bbsPosi           : out std_logic;
      bbsPiso           : in std_logic;

      -- Status ports --
      statusMzn         : in std_logic_vector(kWidthStatusMzn-1 downto 0);
      statusBase        : out std_logic_vector(kWidthStatusBase-1 downto 0)

);
end MznInterfaceS;

architecture RTL of MznInterfaceS is


begin
  -- ==================================== body ===================================
  -- System ports ----------------------------------------------------------------
  u_frst_inst : IBUFDS
    generic map ( DIFF_TERM => TRUE, IBUF_LOW_PWR => TRUE, IOSTANDARD => "LVDS_25")
    port map ( O => forceReset, I => FRST_P, IB => FRST_N );

  u_clkhul_inst : IBUFDS
    generic map ( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25")
    port map ( O => clkHul, I => CLKHUL_P, IB => CLKHUL_N );

  u_slotpos_inst : IBUFDS
    generic map ( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25")
    port map ( O => slotPosition, I => SLOT_POS_P, IB => SLOT_POS_N );

  -- Bct Bus Bridge --------------------------------------------------------------
  u_prim_active : IBUFDS
    generic map ( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25")
    port map ( O => bbsPrimActive, I => BBS_PRI_ACTIVE_P, IB => BBS_PRI_ACTIVE_N );

  u_scnd_req : OBUFDS
    generic map ( IOSTANDARD => "LVDS_25", SLEW => "SLOW" )
    port map ( O => BBS_SCN_REQ_P, OB => BBS_SCN_REQ_N, I => bbsScndReq);

  u_clk : IBUFDS
    generic map ( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25")
    port map ( O => bbsClk, I => BBS_CLK_P, IB => BBS_CLK_N );

  u_posi : IBUFDS
    generic map ( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25")
    port map ( O => bbsPosi, I => BBS_POSI_P, IB => BBS_POSI_N );

  u_piso : OBUFDS
    generic map ( IOSTANDARD => "LVDS_25", SLEW => "SLOW" )
    port map ( O => BBS_PISO_P, OB => BBS_PISO_N, I => bbsPiso);


  -- STATUS ----------------------------------------------------------------------
  gen_status_mzn : for i in 0 to kWidthStatusMzn-1 generate
    u_ods_status_inst : OBUFDS
      generic map ( IOSTANDARD => "LVDS_25", SLEW => "SLOW")
      port map ( O => STATUS_MZN_P(i), OB => STATUS_MZN_N(i), I => statusMzn(i) );
  end generate;

  gen_status_base : for i in 0 to kWidthStatusBase-1 generate
    u_ids_status_inst : IBUFDS
      generic map ( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25")
      port map ( O => statusBase(i), I => STATUS_BASE_P(i), IB => STATUS_BASE_N(i) );
  end generate;


end RTL;
