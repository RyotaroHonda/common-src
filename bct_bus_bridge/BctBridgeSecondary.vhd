library IEEE, mylib;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use mylib.defBCT.all;
use mylib.defBctBridge.all;

entity BctBridgeSecondary is
  generic(
    enDebug             : boolean:= false
  );
  port(
    rst	                : in std_logic;
    clk	                : in std_logic;

    -- BCT I/F --
    addrBct     	      : out BctBridgeAddrType;
    rxdOut         	    : out LocalBusInType;
    txdIn         	    : in LocalBusOutType;
    reBct	     	        : out std_logic;
    weBct     		      : out std_logic;
    ackBct      	      : in std_logic;

    -- Bus Bridge I/F --
    primIsActive        : in std_logic;
    scndReq             : out std_logic;
    clkBridge           : in std_logic;
    posi                : in std_logic;
    piso               : out std_logic

    );
end BctBridgeSecondary;

architecture RTL of BctBridgeSecondary is
  attribute mark_debug        : boolean;

  -- System --
  signal sync_reset           : std_logic;

  -- internal signal declaration --------------------------------------
  -- SPI-IF --
  signal reg_sr_rxd           : std_logic_vector(kWidthBctData-1 downto 0);
  signal reg_sr_txd           : std_logic_vector(kWidthBctData-1 downto 0);
  signal reg_secondary_req    : std_logic;
  signal buf_secondary_req    : std_logic;
  signal reg_sr_ack           : std_logic_vector(kWidthAckSr-1 downto 0);
  signal set_txd              : std_logic;

  -- BctBridge --
  signal buf_prim_active      : std_logic;
  signal sync_prim_active     : std_logic;
  signal edge_prim_active     : std_logic_vector(1 downto 0);

  signal addr_bct             : BctBridgeAddrType;
  signal rxd_bct              : LocalBusInType;
  signal txd_bct              : LocalBusOutType;
  signal re_bct, we_bct       : std_logic;
  signal ack_bct              : std_logic;

  -- debug --
  attribute mark_debug of sync_prim_active  : signal is enDebug;
  attribute mark_debug of reg_secondary_req : signal is enDebug;
  attribute mark_debug of addr_bct          : signal is enDebug;
  attribute mark_debug of rxd_bct           : signal is enDebug;
  attribute mark_debug of txd_bct           : signal is enDebug;
  attribute mark_debug of re_bct            : signal is enDebug;
  attribute mark_debug of we_bct            : signal is enDebug;
  attribute mark_debug of ack_bct           : signal is enDebug;

  attribute mark_debug of reg_sr_rxd           : signal is enDebug;
  attribute mark_debug of reg_sr_txd           : signal is enDebug;

-- =============================== body ===============================
begin
  -- Serial I/F --
  piso      <= reg_sr_txd(kWidthBctData-1);
  scndReq   <= buf_secondary_req;

  -- Bct I/F --
  addrBct   <= addr_bct;
  rxdOut    <= rxd_bct;
  reBct     <= re_bct;
  weBct     <= we_bct;
  ack_bct   <= ackBct;

  ---------------------------------------------------------------------
  -- Serial interface
  ---------------------------------------------------------------------
  u_sr_rx : process(clkBridge)
  begin
    if(clkBridge'event and clkBridge = '1') then
      if(primIsActive = '1') then
        reg_sr_rxd  <= reg_sr_rxd(kWidthBctData-2 downto 0) & posi;
      end if;
    end if;
  end process;

  u_sr_tx : process(clkBridge, set_txd)
  begin
    if(set_txd = '1') then
      reg_sr_txd  <= kComAck & addr_bct & txd_bct;
    elsif(clkBridge'event and clkBridge = '1') then
      if(primIsActive = '1') then
        reg_sr_txd  <= reg_sr_txd(kWidthBctData-2 downto 0) & '0';
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------
  -- BCT bus bridge secondary functions
  ---------------------------------------------------------------------

  u_buf : process(clk)
  begin
    if(clk'event and clk = '1') then
      buf_prim_active   <= primIsActive;
      buf_secondary_req <= reg_secondary_req;
    end if;
  end process;

  u_sync : entity mylib.synchronizer
    port map(clk, buf_prim_active, sync_prim_active);

  u_rx_sequence : process(clk)
  begin
    if(clk'event and clk = '1') then
      if(sync_reset = '1') then
        we_bct  <= '0';
        re_bct  <= '0';
      else
        edge_prim_active  <= edge_prim_active(0) & sync_prim_active;

        if(edge_prim_active = "10") then

          addr_bct  <= reg_sr_rxd(23 downto 8);
          rxd_bct   <= reg_sr_rxd(7 downto 0);

          if(reg_sr_rxd(kWidthBctData-1 downto kWidthBctData-8) = kComWrite) then
            we_bct  <= '1';
          elsif(reg_sr_rxd(kWidthBctData-1 downto kWidthBctData-8) = kComRead) then
            re_bct  <= '1';
          end if;
        else
          we_bct  <= '0';
          re_bct  <= '0';
        end if;
      end if;
    end if;
  end process;

  u_tx_sequence : process(clk)
  begin
    if(clk'event and clk = '1') then
      if(sync_reset = '1') then
        reg_secondary_req <= '0';
      else
        reg_sr_ack  <= reg_sr_ack(kWidthAckSr-2 downto 0) & ack_bct;
        if(ack_bct = '1') then
          txd_bct     <= txdIn;
        end if;

        if(reg_sr_ack(1 downto 0) = "01") then
          set_txd   <= '1';
        else
          set_txd   <= '0';
        end if;

        if(reg_sr_ack(kWidthAckSr-1 downto kWidthAckSr-2) = "01") then
          reg_secondary_req   <= '1';
        elsif(edge_prim_active = "10") then
          reg_secondary_req   <= '0';
        end if;
      end if;
    end if;
  end process;


  -- Reset sequence --
  u_reset_gen_sys   : entity mylib.ResetGen
    port map(rst, clk, sync_reset);

end RTL;
