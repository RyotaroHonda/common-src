library IEEE, mylib;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use mylib.defBCT.all;
use mylib.defSPI_IF.all;
use mylib.defBctBridge.all;

library UNISIM;
use UNISIM.VComponents.all;

entity BctBridgePrimary is
  generic(
    invClk              : std_logic;
    enDebug             : boolean:=false
  );
  port(
    rst	                : in std_logic;
    clk	                : in std_logic;

    -- Bus Bridge I/F --
    primIsActive        : out std_logic;
    scndReq             : in std_logic;
    clkBridge           : out std_logic;
    piso                : in  std_logic;
    posi                : out std_logic;

    -- Local bus --
    addrLocalBus	      : in LocalAddressType;
    dataLocalBusIn	    : in LocalBusInType;
    dataLocalBusOut	    : out LocalBusOutType;
    reLocalBus		      : in std_logic;
    weLocalBus		      : in std_logic;
    readyLocalBus	      : out std_logic
    );
end BctBridgePrimary;

architecture RTL of BctBridgePrimary is
  attribute mark_debug        : boolean;

  -- System --
  signal sync_reset           : std_logic;

  -- internal signal declaration --------------------------------------
  -- SPI-IF --
  signal busy_cycle           : std_logic;
  signal reg_busy_cycle       : std_logic_vector(1 downto 0);
  signal sync_scnd_req        : std_logic;

  signal start_spi_if         : std_logic;
  signal read_phase           : std_logic;
  signal busy_if              : std_logic;
  signal reg_txd_if           : std_logic_vector(kWidthBctData-1 downto 0);
  signal reg_rxd_if           : std_logic_vector(kWidthBctData-1 downto 0);
  signal spi_txd, spi_rxd     : std_logic_vector(kWidthDataPerCycle-1 downto 0);

  signal state_spi            : BridgeIfProcessType;

  -- Local bus --
  signal start_a_cycle        : std_logic;
  signal reg_txd_lbus         : std_logic_vector(kWidthBctData-1 downto 0);
  signal reg_rxd_lbus         : std_logic_vector(kWidthBctData-1 downto 0);

  signal state_lbus	          : BBPBusProcessType;

  -- debug --
  attribute mark_debug of reg_busy_cycle  : signal is enDebug;
  attribute mark_debug of start_a_cycle   : signal is enDebug;
  attribute mark_debug of start_spi_if    : signal is enDebug;
  attribute mark_debug of busy_if         : signal is enDebug;
  attribute mark_debug of reg_txd_if      : signal is enDebug;
  attribute mark_debug of spi_txd         : signal is enDebug;
  attribute mark_debug of spi_rxd         : signal is enDebug;
  attribute mark_debug of state_spi       : signal is enDebug;
  attribute mark_debug of sync_scnd_req   : signal is enDebug;
  attribute mark_debug of reg_rxd_lbus    : signal is enDebug;

-- =============================== body ===============================
begin
  ---------------------------------------------------------------------
  -- BCT bus bridge primary functions
  --------------------------------------------------------------------
  u_iobuf : process(clk)
  begin
    if(clk'event and clk = '1') then
      primIsActive  <= busy_cycle;
    end if;
  end process;

  u_sync_req : entity mylib.synchronizer
    port map(clk, scndReq, sync_scnd_req);

  u_BridgeProcess : process(clk)
    variable index : integer range -1 to kNbytePayload;
  begin
    if(clk'event and clk = '1') then
      if(sync_reset = '1') then
        index             := kNbytePayload-1;
        start_spi_if      <= '0';
        busy_cycle        <= '0';
        read_phase        <= '0';
        reg_rxd_lbus      <= (others => '0');
        state_spi         <= Idle;
      else
        case state_spi is
          when Idle =>
            start_spi_if      <= '0';
            read_phase        <= '0';

            if(start_a_cycle = '1') then
              -- Write sequence to secondary --
              index           := kNbytePayload-1;
              reg_txd_if      <= reg_txd_lbus;
              state_spi       <= StartIF;
            end if;

          when StartIF =>
            busy_cycle      <= '1';
            spi_txd         <= reg_txd_if(8*(index+1)-1 downto 8*index);

            if(busy_if = '1') then
              start_spi_if  <= '0';
              state_spi     <= WaitSpiDone;
            else
              start_spi_if    <= '1';
            end if;

          when WaitSpiDone =>
            if(busy_if = '0') then
              reg_rxd_lbus(8*(index+1)-1 downto 8*index)  <= spi_rxd;

              if(index = 0 and read_phase = '1') then
                state_spi     <= Finalize;
              elsif(index = 0 and read_phase = '0') then
                busy_cycle    <= '0';
                read_phase    <= '1';
                state_spi     <= Wait2ndryReq;
              else
                index         := index -1;
                state_spi     <= StartIF;
              end if;
            end if;

          when Wait2ndryReq =>
            reg_txd_if  <= kComAck & X"000000";
            index       := kNbytePayload-1;
            if(sync_scnd_req = '1') then
              state_spi   <= StartIF;
            end if;


          when Finalize =>
            busy_cycle  <= '0';
            read_phase  <= '0';
            state_spi   <= Idle;

          when others =>
            state_spi        <= Idle;

        end case;
      end if;
    end if;
  end process;

  u_reg_busy : process(clk)
  begin
    if(clk'event and clk = '1') then
      reg_busy_cycle  <= reg_busy_cycle(0) & busy_cycle;
    end if;
  end process;

  u_spi : entity mylib.SPI_IF
    generic map(
      genSTARTUPE2  => false,
      invClk        => invClk
    )
    port map(
      clk         => clk,
      rst         => sync_reset,

      dIn         => spi_txd,
      dOut        => spi_rxd,
      start       => start_spi_if,
      busy        => busy_if,

      sclkSpi     => clkBridge,
      mosiSpi     => posi,
      misoSpi     => piso
      );

  ---------------------------------------------------------------------
  -- Local bus process
  ---------------------------------------------------------------------
  u_BusProcess : process(clk)
  begin
    if(clk'event and clk = '1') then
      if(sync_reset = '1') then
        start_a_cycle   <= '0';
        reg_txd_lbus    <= (others => '0');
        state_lbus	    <= Init;
      else
        case state_lbus is
          when Init =>
            start_a_cycle   <= '0';
            reg_txd_lbus    <= (others => '0');
            dataLocalBusOut <= x"00";
            readyLocalBus		<= '0';
            state_lbus		  <= Idle;

          when Idle =>
            readyLocalBus	<= '0';
            if(weLocalBus = '1' or reLocalBus = '1') then
              state_lbus	<= Connect;
            end if;

          when Connect =>
            if(weLocalBus = '1') then
              state_lbus	<= Write;
            else
              state_lbus	<= Read;
            end if;

          when Write =>
            case addrLocalBus(kNonMultiByte'range) is
              when kTxd(kNonMultiByte'range) =>
                if( addrLocalBus(kMultiByte'range) = k1stbyte) then
                  reg_txd_lbus(7 downto 0)	  <= dataLocalBusIn;
                elsif( addrLocalBus(kMultiByte'range) = k2ndbyte) then
                  reg_txd_lbus(15 downto 8)	  <= dataLocalBusIn;
                elsif( addrLocalBus(kMultiByte'range) = k3rdbyte) then
                  reg_txd_lbus(23 downto 16)	<= dataLocalBusIn;
                elsif( addrLocalBus(kMultiByte'range) = k4thbyte) then
                  reg_txd_lbus(31 downto 24)	<= dataLocalBusIn;
                else
                  reg_txd_lbus(31 downto 24)	<= dataLocalBusIn;
                end if;
                state_lbus	 <= Done;

              when kExec(kNonMultiByte'range) =>
                state_lbus	 <= Execute;

              when others =>
                state_lbus	<= Done;
            end case;

          when Read =>
            case addrLocalBus(kNonMultiByte'range) is
              when kRxd(kNonMultiByte'range) =>
                if( addrLocalBus(kMultiByte'range) = k1stbyte) then
                  dataLocalBusOut   <= reg_rxd_lbus(7 downto 0);
                elsif( addrLocalBus(kMultiByte'range) = k2ndbyte) then
                  dataLocalBusOut   <= reg_rxd_lbus(15 downto 8);
                elsif( addrLocalBus(kMultiByte'range) = k3rdbyte) then
                  dataLocalBusOut   <= reg_rxd_lbus(23 downto 16);
                elsif( addrLocalBus(kMultiByte'range) = k4thbyte) then
                  dataLocalBusOut   <= reg_rxd_lbus(31 downto 24);
                else
                  dataLocalBusOut   <= reg_rxd_lbus(31 downto 24);
                end if;

              when others => null;

            end case;
            state_lbus	 <= Done;

          when Execute =>
            start_a_cycle   <= '1';
            state_lbus      <= WaitDone;

          when WaitDone =>
            start_a_cycle   <= '0';
            if(state_spi = Finalize) then
              state_lbus    <= Finalize;
            end if;

          when Finalize =>
            state_lbus      <= Done;

          when Done =>
            readyLocalBus	<= '1';
            if(weLocalBus = '0' and reLocalBus = '0') then
              state_lbus	<= Idle;
            end if;

          -- probably this is error --
          when others =>
            state_lbus	<= Init;
        end case;
      end if;
    end if;
  end process u_BusProcess;

  -- Reset sequence --
  u_reset_gen_sys   : entity mylib.ResetGen
    port map(rst, clk, sync_reset);

end RTL;

