-------------------------------------------------------------------------------
-- Title      : Toplevel module for KCU105 eval board.
-- Project    : K7UGbE
-------------------------------------------------------------------------------
-- File       : top.vhd
-- Author     : Yuan Mei
-- Company    : LBNL
-- Created    : 2016-11-19
-- Last update: 2016-11-19
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Kintex-7 Ultrascale xcku040ffva1156e-2
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-19  1.0      ymei	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY top IS
  GENERIC (
    ENABLE_DEBUG       : boolean := false;
    ENABLE_GIG_ETH     : boolean := true;
    ENABLE_TEN_GIG_ETH : boolean := true
  );
  PORT (
    SYS_RST      : IN    std_logic;
    SYS_CLK_P    : IN    std_logic;     -- 300MHz
    SYS_CLK_N    : IN    std_logic;
    SYS125_CLK_P : IN    std_logic;     -- 125MHz
    SYS125_CLK_N : IN    std_logic;
    USER_CLK_P   : IN    std_logic;     -- 156.250MHz
    USER_CLK_N   : IN    std_logic;
    --
    LED8Bit      : OUT   std_logic_vector(7 DOWNTO 0);
    DIPSw4Bit    : IN    std_logic_vector(3 DOWNTO 0);
    BTN5Bit      : IN    std_logic_vector(4 DOWNTO 0);
    -- UART via usb
    USB_RX       : IN    std_logic;
    USB_TX       : OUT   std_logic;
    USB_RTS      : OUT   std_logic;
    USB_CTS      : IN    std_logic;
    -- Gigbit eth interface (SGMII)
    PHY_RESET_N  : OUT   std_logic;
    MDIO         : INOUT std_logic;
    MDC          : OUT   std_logic;
    SGMII_CLK_P  : IN    std_logic;     -- 625MHz
    SGMII_CLK_N  : IN    std_logic;
    SGMII_RX_P   : IN    std_logic;
    SGMII_RX_N   : IN    std_logic;
    SGMII_TX_P   : OUT   std_logic;
    SGMII_TX_N   : OUT   std_logic
  );
END top;

ARCHITECTURE Behavioral OF top IS
  -- Components
  COMPONENT global_clock_reset
    PORT (
      SYS_CLK_P  : IN  std_logic;
      SYS_CLK_N  : IN  std_logic;
      FORCE_RST  : IN  std_logic;
      -- output
      GLOBAL_RST : OUT std_logic;
      SYS_CLK    : OUT std_logic;
      CLK_OUT1   : OUT std_logic;
      CLK_OUT2   : OUT std_logic;
      CLK_OUT3   : OUT std_logic;
      CLK_OUT4   : OUT std_logic
    );
  END COMPONENT;
  ---------------------------------------------< gig_eth
  COMPONENT gig_eth
    PORT (
      -- asynchronous reset
      GLBL_RST             : IN    std_logic;
      -- clocks
      SYS_CLK              : IN    std_logic;
      SGMII125_CLK         : OUT   std_logic;  -- routed back OUT, single-ended
      -- PHY interface
      PHY_RESETN           : OUT   std_logic;
      -- SGMII interface
      SGMII_CLK_P          : IN    std_logic;
      SGMII_CLK_N          : IN    std_logic;
      SGMII_RX_P           : IN    std_logic;
      SGMII_RX_N           : IN    std_logic;
      SGMII_TX_P           : OUT   std_logic;
      SGMII_TX_N           : OUT   std_logic;
      -- MDIO interface
      MDIO                 : INOUT std_logic;
      MDC                  : OUT   std_logic;
      -- status
      STATUS               : OUT   std_logic_vector(31 DOWNTO 0);
      -- TCP
      MAC_ADDR             : IN    std_logic_vector(47 DOWNTO 0);
      IPv4_ADDR            : IN    std_logic_vector(31 DOWNTO 0);
      IPv6_ADDR            : IN    std_logic_vector(127 DOWNTO 0);
      SUBNET_MASK          : IN    std_logic_vector(31 DOWNTO 0);
      GATEWAY_IP_ADDR      : IN    std_logic_vector(31 DOWNTO 0);
      TCP_CONNECTION_RESET : IN    std_logic;
      TX_TDATA             : IN    std_logic_vector(7 DOWNTO 0);
      TX_TVALID            : IN    std_logic;
      TX_TREADY            : OUT   std_logic;
      RX_TDATA             : OUT   std_logic_vector(7 DOWNTO 0);
      RX_TVALID            : OUT   std_logic;
      RX_TREADY            : IN    std_logic;
      -- FIFO
      TCP_USE_FIFO         : IN    std_logic;
      TX_FIFO_WRCLK        : IN    std_logic;
      TX_FIFO_Q            : IN    std_logic_vector(31 DOWNTO 0);
      TX_FIFO_WREN         : IN    std_logic;
      TX_FIFO_FULL         : OUT   std_logic;
      RX_FIFO_RDCLK        : IN    std_logic;
      RX_FIFO_Q            : OUT   std_logic_vector(31 DOWNTO 0);
      RX_FIFO_RDEN         : IN    std_logic;
      RX_FIFO_EMPTY        : OUT   std_logic
    );
  END COMPONENT;
  ---------------------------------------------> gig_eth
  COMPONENT control_interface
    PORT (
      RESET           : IN  std_logic;
      CLK             : IN  std_logic;    -- system clock
      -- From FPGA to PC
      FIFO_Q          : OUT std_logic_vector(35 DOWNTO 0);  -- interface fifo data output port
      FIFO_EMPTY      : OUT std_logic;    -- interface fifo "emtpy" signal
      FIFO_RDREQ      : IN  std_logic;    -- interface fifo read request
      FIFO_RDCLK      : IN  std_logic;    -- interface fifo read clock
      -- From PC to FPGA, FWFT
      CMD_FIFO_Q      : IN  std_logic_vector(35 DOWNTO 0);  -- interface command fifo data out port
      CMD_FIFO_EMPTY  : IN  std_logic;    -- interface command fifo "emtpy" signal
      CMD_FIFO_RDREQ  : OUT std_logic;    -- interface command fifo read request
      -- Digital I/O
      CONFIG_REG      : OUT std_logic_vector(511 DOWNTO 0); -- thirtytwo 16bit registers
      PULSE_REG       : OUT std_logic_vector(15 DOWNTO 0);  -- 16bit pulse register
      STATUS_REG      : IN  std_logic_vector(175 DOWNTO 0); -- eleven 16bit registers
      -- Memory interface
      MEM_WE          : OUT std_logic;    -- memory write enable
      MEM_ADDR        : OUT std_logic_vector(31 DOWNTO 0);
      MEM_DIN         : OUT std_logic_vector(31 DOWNTO 0);  -- memory data input
      MEM_DOUT        : IN  std_logic_vector(31 DOWNTO 0);  -- memory data output
      -- Data FIFO interface, FWFT
      DATA_FIFO_Q     : IN  std_logic_vector(31 DOWNTO 0);
      DATA_FIFO_EMPTY : IN  std_logic;
      DATA_FIFO_RDREQ : OUT std_logic;
      DATA_FIFO_RDCLK : OUT std_logic
    );
  END COMPONENT;
  COMPONENT pulse2pulse
    PORT (
      IN_CLK   : IN  std_logic;
      OUT_CLK  : IN  std_logic;
      RST      : IN  std_logic;
      PULSEIN  : IN  std_logic;
      INBUSY   : OUT std_logic;
      PULSEOUT : OUT std_logic
    );
  END COMPONENT;
  COMPONENT edge_sync IS
    GENERIC (
      EDGE : std_logic := '1'  -- '1'  :  rising edge,  '0' falling edge
    );
    PORT (
      RESET : IN  std_logic;
      CLK   : IN  std_logic;
      EI    : IN  std_logic;
      SO    : OUT std_logic
    );
  END COMPONENT;
  COMPONENT pulsegen
    GENERIC (
      COUNTER_WIDTH : positive := 16
    );
    PORT (
      CLK    : IN  std_logic;
      PERIOD : IN  std_logic_vector(COUNTER_WIDTH-1 DOWNTO 0);
      I      : IN  std_logic;
      O      : OUT std_logic
    );
  END COMPONENT;
  COMPONENT clk_div IS
    GENERIC (
      WIDTH : positive := 16;
      PBITS : positive := 4             -- log2(WIDTH)
    );
    PORT (
      RESET   : IN  std_logic;
      CLK     : IN  std_logic;
      DIV     : IN  std_logic_vector(PBITS-1 DOWNTO 0);
      CLK_DIV : OUT std_logic
    );
  END COMPONENT;
  COMPONENT clk_fwd
    GENERIC (
      INV : boolean := false
    );
    PORT (
      R : IN  std_logic;
      I : IN  std_logic;
      O : OUT std_logic
    );
  END COMPONENT;
  ---------------------------------------------< debug : ILA and VIO (`Chipscope')
  COMPONENT dbg_ila
    PORT (
      CLK    : IN std_logic;
      PROBE0 : IN std_logic_vector(63 DOWNTO 0);
      PROBE1 : IN std_logic_vector(79 DOWNTO 0);
      PROBE2 : IN std_logic_vector(79 DOWNTO 0);
      PROBE3 : IN std_logic_vector(2047 DOWNTO 0)
    );
  END COMPONENT;
  COMPONENT dbg_ila1
    PORT (
      CLK    : IN std_logic;
      PROBE0 : IN std_logic_vector(15 DOWNTO 0);
      PROBE1 : IN std_logic_vector(15 DOWNTO 0)
    );
  END COMPONENT;
  COMPONENT dbg_vio
    PORT (
      CLK        : IN  std_logic;
      PROBE_IN0  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN1  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN2  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN3  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN4  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN5  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN6  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN7  : IN  std_logic_vector(63 DOWNTO 0);
      PROBE_IN8  : IN  std_logic_vector(35 DOWNTO 0);
      PROBE_OUT0 : OUT std_logic_vector(63 DOWNTO 0)
    );
  END COMPONENT;
  ---------------------------------------------> debug : ILA and VIO (`Chipscope')
  -- Signals
  SIGNAL reset                             : std_logic;  
  SIGNAL sys_clk                           : std_logic;
  SIGNAL sys125_clk                        : std_logic;
  SIGNAL clk_50MHz                         : std_logic;
  SIGNAL clk_100MHz                        : std_logic;
  SIGNAL clk_125MHz                        : std_logic;
  SIGNAL clk_200MHz                        : std_logic;
  SIGNAL clk_250MHz                        : std_logic;
  SIGNAL clk156                            : std_logic;
  SIGNAL user_clk                          : std_logic;
  SIGNAL sgmii125_clk                      : std_logic;
  --
  SIGNAL control_clk                       : std_logic;
  SIGNAL control_fifo_q                    : std_logic_vector(35 DOWNTO 0);
  SIGNAL control_fifo_rdreq                : std_logic;
  SIGNAL control_fifo_empty                : std_logic;
  SIGNAL control_fifo_rdclk                : std_logic;
  SIGNAL cmd_fifo_q                        : std_logic_vector(35 DOWNTO 0);
  SIGNAL cmd_fifo_empty                    : std_logic;
  SIGNAL cmd_fifo_rdreq                    : std_logic;
  -- thirtytwo 16bit registers  
  SIGNAL config_reg                        : std_logic_vector(511 DOWNTO 0);
  -- 16bit pulse register
  SIGNAL pulse_reg                         : std_logic_vector(15 DOWNTO 0);
  -- eleven 16bit registers
  SIGNAL status_reg                        : std_logic_vector(175 DOWNTO 0) := (OTHERS => '0');
  SIGNAL control_mem_we                    : std_logic;
  SIGNAL control_mem_addr                  : std_logic_vector(31 DOWNTO 0);
  SIGNAL control_mem_din                   : std_logic_vector(31 DOWNTO 0);
  --
  SIGNAL usr_data_output                   : std_logic_vector (7 DOWNTO 0);
  ---------------------------------------------< gig_eth
  SIGNAL gig_eth_mac_addr                  : std_logic_vector(47 DOWNTO 0);
  SIGNAL gig_eth_ipv4_addr                 : std_logic_vector(31 DOWNTO 0);
  SIGNAL gig_eth_subnet_mask               : std_logic_vector(31 DOWNTO 0);
  SIGNAL gig_eth_gateway_ip_addr           : std_logic_vector(31 DOWNTO 0);
  SIGNAL gig_eth_tx_tdata                  : std_logic_vector(7 DOWNTO 0);
  SIGNAL gig_eth_tx_tvalid                 : std_logic;
  SIGNAL gig_eth_tx_tready                 : std_logic;  
  SIGNAL gig_eth_rx_tdata                  : std_logic_vector(7 DOWNTO 0);
  SIGNAL gig_eth_rx_tvalid                 : std_logic;
  SIGNAL gig_eth_rx_tready                 : std_logic;
  SIGNAL gig_eth_tcp_use_fifo              : std_logic;
  SIGNAL gig_eth_tx_fifo_wrclk             : std_logic;
  SIGNAL gig_eth_tx_fifo_q                 : std_logic_vector(31 DOWNTO 0);
  SIGNAL gig_eth_tx_fifo_wren              : std_logic;
  SIGNAL gig_eth_tx_fifo_full              : std_logic;
  SIGNAL gig_eth_rx_fifo_rdclk             : std_logic;
  SIGNAL gig_eth_rx_fifo_q                 : std_logic_vector(31 DOWNTO 0);
  SIGNAL gig_eth_rx_fifo_rden              : std_logic;
  SIGNAL gig_eth_rx_fifo_empty             : std_logic;
  SIGNAL gig_eth_status                    : std_logic_vector(31 DOWNTO 0);
  ---------------------------------------------> gig_eth
  ---------------------------------------------< debug
  SIGNAL dbg_ila_probe0                    : std_logic_vector (63 DOWNTO 0);
  SIGNAL dbg_ila_probe1                    : std_logic_vector (79 DOWNTO 0);
  SIGNAL dbg_ila_probe2                    : std_logic_vector (79 DOWNTO 0);
  SIGNAL dbg_ila_probe3                    : std_logic_vector (2047 DOWNTO 0);
  SIGNAL dbg_vio_probe_out0                : std_logic_vector (63 DOWNTO 0);
  SIGNAL dbg_ila1_probe0                   : std_logic_vector (15 DOWNTO 0);
  SIGNAL dbg_ila1_probe1                   : std_logic_vector (15 DOWNTO 0);
  ATTRIBUTE mark_debug                     : string;
  ATTRIBUTE keep                           : string;
  -- ATTRIBUTE mark_debug OF USB_TX                  : SIGNAL IS "true";
  ---------------------------------------------> debug

BEGIN
  ---------------------------------------------< Clock and reset
  global_clock_reset_inst : global_clock_reset
    PORT MAP (
      SYS_CLK_P  => SYS_CLK_P,
      SYS_CLK_N  => SYS_CLK_N,
      FORCE_RST  => SYS_RST,
      -- output
      GLOBAL_RST => reset,
      SYS_CLK    => sys_clk,
      CLK_OUT1   => clk_50MHz,
      CLK_OUT2   => clk_100MHz,
      CLK_OUT3   => OPEN,
      CLK_OUT4   => clk_250MHz
    );
  sys125_clk_ibuf : IBUFGDS
    GENERIC MAP (
      DIFF_TERM => FALSE                -- external termination available
    )
    PORT MAP (
      O  => sys125_clk,
      I  => SYS125_CLK_P,
      IB => SYS125_CLK_N
    );  
  user_clk_ibuf : IBUFGDS
    GENERIC MAP (
      DIFF_TERM => FALSE                -- external termination available
    )
    PORT MAP (
      O  => user_clk,
      I  => USER_CLK_P,
      IB => USER_CLK_N
    );
  ---------------------------------------------> Clock and reset

  ---------------------------------------------< control_interface
  control_clk <= clk_100MHz;
  control_interface_inst : control_interface
    PORT MAP (
      RESET => reset,
      CLK   => control_clk,
      -- From FPGA to PC
      FIFO_Q          => control_fifo_q,
      FIFO_EMPTY      => control_fifo_empty,
      FIFO_RDREQ      => control_fifo_rdreq,
      FIFO_RDCLK      => control_fifo_rdclk,
      -- From PC to FPGA, FWFT
      CMD_FIFO_Q      => cmd_fifo_q,
      CMD_FIFO_EMPTY  => cmd_fifo_empty,
      CMD_FIFO_RDREQ  => cmd_fifo_rdreq,
      -- Digital I/O
      CONFIG_REG      => config_reg,
      PULSE_REG       => pulse_reg,
      STATUS_REG      => status_reg,
      -- Memory interface
      MEM_WE          => control_mem_we,
      MEM_ADDR        => control_mem_addr,
      MEM_DIN         => control_mem_din,
      MEM_DOUT        => (OTHERS => '0'),
      -- Data FIFO interface, FWFT
      DATA_FIFO_Q     => (OTHERS => '0'),
      DATA_FIFO_EMPTY => '1',
      DATA_FIFO_RDREQ => OPEN,
      DATA_FIFO_RDCLK => OPEN
    );
  ---------------------------------------------> control_interface
  ---------------------------------------------< gig_eth
  gig_eth_cores : IF ENABLE_GIG_ETH GENERATE
    gig_eth_mac_addr(gig_eth_mac_addr'length-1 DOWNTO 4)   <= x"000a3502a75";
    gig_eth_mac_addr(3 DOWNTO 0)                           <= DIPSw4Bit;
    gig_eth_ipv4_addr(gig_eth_ipv4_addr'length-1 DOWNTO 4) <= x"c0a8020";
    gig_eth_ipv4_addr(3 DOWNTO 0)                          <= DIPSw4Bit;
    gig_eth_subnet_mask                                    <= x"ffffff00";
    gig_eth_gateway_ip_addr                                <= x"c0a80201";
    gig_eth_inst : gig_eth
      PORT MAP (
        -- asynchronous reset
        GLBL_RST             => reset,
        -- clocks
        SYS_CLK              => sys_clk,
        SGMII125_CLK         => sgmii125_clk,    -- routed back out, single-ended        
        -- PHY interface
        PHY_RESETN           => PHY_RESET_N,
        -- SGMII interface
        SGMII_CLK_P          => SGMII_CLK_P,
        SGMII_CLK_N          => SGMII_CLK_N,
        SGMII_RX_P           => SGMII_RX_P,
        SGMII_RX_N           => SGMII_RX_N,
        SGMII_TX_P           => SGMII_TX_P,
        SGMII_TX_N           => SGMII_TX_N,
        -- MDIO interface
        MDIO                 => MDIO,
        MDC                  => MDC,
        -- status
        STATUS               => gig_eth_status,
        -- TCP
        MAC_ADDR             => gig_eth_mac_addr,
        IPv4_ADDR            => gig_eth_ipv4_addr,
        IPv6_ADDR            => (OTHERS => '0'),
        SUBNET_MASK          => gig_eth_subnet_mask,
        GATEWAY_IP_ADDR      => gig_eth_gateway_ip_addr,
        TCP_CONNECTION_RESET => '0',
        TX_TDATA             => gig_eth_tx_tdata,
        TX_TVALID            => gig_eth_tx_tvalid,
        TX_TREADY            => gig_eth_tx_tready,
        RX_TDATA             => gig_eth_rx_tdata,
        RX_TVALID            => gig_eth_rx_tvalid,
        RX_TREADY            => gig_eth_rx_tready,
        -- FIFO
        TCP_USE_FIFO         => gig_eth_tcp_use_fifo,
        TX_FIFO_WRCLK        => gig_eth_tx_fifo_wrclk,
        TX_FIFO_Q            => gig_eth_tx_fifo_q,
        TX_FIFO_WREN         => gig_eth_tx_fifo_wren,
        TX_FIFO_FULL         => gig_eth_tx_fifo_full,
        RX_FIFO_RDCLK        => gig_eth_rx_fifo_rdclk,
        RX_FIFO_Q            => gig_eth_rx_fifo_q,
        RX_FIFO_RDEN         => gig_eth_rx_fifo_rden,
        RX_FIFO_EMPTY        => gig_eth_rx_fifo_empty
      );
    dbg_ila_probe0(26 DOWNTO 19) <= gig_eth_rx_tdata;
    dbg_ila_probe0(27)           <= gig_eth_rx_tvalid;
    dbg_ila_probe0(28)           <= gig_eth_rx_tready;

    -- loopback
    --gig_eth_tx_tdata  <= gig_eth_rx_tdata;
    --gig_eth_tx_tvalid <= gig_eth_rx_tvalid;
    --gig_eth_rx_tready <= gig_eth_tx_tready;

    -- receive to cmd_fifo
    gig_eth_tcp_use_fifo         <= '1';
    gig_eth_rx_fifo_rdclk        <= control_clk;
    cmd_fifo_q(31 DOWNTO 0)      <= gig_eth_rx_fifo_q;
    dbg_ila_probe0(63 DOWNTO 32) <= gig_eth_rx_fifo_q;
    cmd_fifo_empty               <= gig_eth_rx_fifo_empty;
    gig_eth_rx_fifo_rden         <= cmd_fifo_rdreq;

    -- send control_fifo data through gig_eth_tx_fifo
    gig_eth_tx_fifo_wrclk <= sys125_clk;
    -- connect FWFT fifo interface
    control_fifo_rdclk    <= gig_eth_tx_fifo_wrclk;
    gig_eth_tx_fifo_q     <= control_fifo_q(31 DOWNTO 0);
    gig_eth_tx_fifo_wren  <= NOT control_fifo_empty;
    control_fifo_rdreq    <= NOT gig_eth_tx_fifo_full;
  END GENERATE gig_eth_cores;
  ---------------------------------------------> gig_eth

  --PROCESS (sys125_clk, reset) IS
  --  VARIABLE led_cnt : unsigned(25 DOWNTO 0) := (OTHERS => '0');
  --BEGIN  -- PROCESS
  --  IF reset = '1' THEN                 -- asynchronous reset (active high)
  --    led_cnt := (OTHERS => '0');
  --  ELSIF rising_edge(sys125_clk) THEN  -- rising clock edge
  --    led_cnt                     := led_cnt + 1;
  --    usr_data_output(1 DOWNTO 0) <= std_logic_vector(led_cnt(25-2 DOWNTO 22));
  --  END IF;
  --END PROCESS;

  PROCESS (sgmii125_clk, reset) IS
    VARIABLE led_cnt : unsigned(25 DOWNTO 0) := (OTHERS => '0');
  BEGIN  -- PROCESS
    IF reset = '1' THEN                   -- asynchronous reset (active high)
      led_cnt := (OTHERS => '0');
    ELSIF rising_edge(sgmii125_clk) THEN  -- rising clock edge
      led_cnt                     := led_cnt + 1;
      usr_data_output(1 DOWNTO 0) <= std_logic_vector(led_cnt(25-2 DOWNTO 22));
    END IF;
  END PROCESS;

  usr_data_output(7 DOWNTO 2) <= gig_eth_status(16) & gig_eth_status(7) & gig_eth_status(3 DOWNTO 0);
  -- usr_data_output <= gig_eth_status(15 DOWNTO 8);

  led_obufs : FOR i IN 0 TO 7 GENERATE
    led_obuf : OBUF
      PORT MAP (
        I => usr_data_output(i),
        O => LED8Bit(i)
      );
  END GENERATE led_obufs;

END Behavioral;
