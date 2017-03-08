--------------------------------------------------------------------------------
--! @file top.vhd
--! @brief Toplevel module for KCU105 eval board.
--! @author Yuan Mei
--!
--! Target Devices: Kintex-7 Ultrascale xcku040ffva1156e-2
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

LIBRARY work;
USE work.utility.ALL;

ENTITY top IS
  GENERIC (
    ENABLE_DEBUG       : boolean := false;
    ENABLE_GIG_ETH     : boolean := true;
    ENABLE_TEN_GIG_ETH : boolean := true
  );
  PORT (
    SYS_RST      : IN    std_logic;
    SYS_CLK_P    : IN    std_logic;     --! 300MHz
    SYS_CLK_N    : IN    std_logic;
    SYS125_CLK_P : IN    std_logic;     --! 125MHz
    SYS125_CLK_N : IN    std_logic;
    USER_CLK_P   : IN    std_logic;     --! 156.250MHz
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
    SGMII_CLK_P  : IN    std_logic;     --! 625MHz
    SGMII_CLK_N  : IN    std_logic;
    SGMII_RX_P   : IN    std_logic;
    SGMII_RX_N   : IN    std_logic;
    SGMII_TX_P   : OUT   std_logic;
    SGMII_TX_N   : OUT   std_logic;
    -- FMC HPC
    FMC_HPC_HA_P     :INOUT    std_logic_vector(23 DOWNTO 0);
    FMC_HPC_HA_N     :INOUT    std_logic_vector(23 DOWNTO 0);
    FMC_HPC_LA_P     :INOUT    std_logic_vector(33 DOWNTO 0);
    FMC_HPC_LA_N     :INOUT    std_logic_vector(33 DOWNTO 0);
    FMC_HPC_CLK1_M2C_P : INOUT std_logic;
    FMC_HPC_CLK1_M2C_N : INOUT std_logic;
    -- FMC LPC
    FMC_LPC_LA_P     :INOUT    std_logic_vector(33 DOWNTO 0);
    FMC_LPC_LA_N     :INOUT    std_logic_vector(33 DOWNTO 0)
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
      SGMII125_CLK         : OUT   std_logic;  -- routed back out, single-ended
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
  ---------------------------------------------< TOP_SR
  COMPONENT Top_SR IS
    GENERIC (
      WIDTH           : positive := 170;
      CNT_WIDTH       : positive := 8;
      DIV_WIDTH       : positive := 6;
      COUNT_WIDTH     : positive := 64;
      VALID_WIDTH     : positive := 32;
      NUM_WIDTH       : positive := 4;
      FIFO_WIDTH      : positive := 36;
      SHIFT_DIRECTION : positive := 1;
      READ_TRIG_SRC   : natural  := 0;
      READ_DELAY      : natural  := 1
    );
    PORT (
      clk_in      :IN   std_logic;
      rst         :IN   std_logic;
      start       :IN   std_logic;
      wr_en       :IN   std_logic;
      din         :IN   std_logic_vector(15 DOWNTO 0);
      data_in_p   :IN   std_logic;
      data_in_n   :IN   std_logic;
      div         :IN   std_logic_vector(5 DOWNTO 0);
      fifo_rd_en  :IN   std_logic;
      clk         :OUT  std_logic;
      clk_sr_p    :OUT  std_logic;
      clk_sr_n    :OUT  std_logic;
      data_out_p  :OUT  std_logic;
      data_out_n  :OUT  std_logic;
      load_sr_p   :OUT  std_logic;
      load_sr_n   :OUT  std_logic;
      fifo_empty  :OUT  std_logic;
      fifo_q      :OUT  std_logic_vector(35 DOWNTO 0)
    );
  END COMPONENT;
  ---------------------------------------------> TOP_SR
  ---------------------------------------------< PULSE_SYNCHRONISE
  COMPONENT pulse_synchronise
    PORT (
      pulse_in     :IN  std_logic;
      clk_in       :IN  std_logic;
      clk_out      :IN  std_logic;
      rst          :IN  std_logic;
      pulse_out    :OUT std_logic
    );
  END COMPONENT;
  ---------------------------------------------> PULSE_SYNCHRONISE
  ---------------------------------------------< shiftreg driver for DAC8568
  COMPONENT fifo2shiftreg
    GENERIC (
      WIDTH   : positive := 32;         -- parallel data width
      CLK_DIV : natural  := 2           -- SCLK freq is CLK / 2**(CLK_DIV)
    );
    PORT (
      CLK      : IN  std_logic;         -- clock
      RESET    : IN  std_logic;         -- reset
      -- input data interface
      WR_CLK   : IN  std_logic;         -- FIFO write clock
      DIN      : IN  std_logic_vector(15 DOWNTO 0);
      WR_EN    : IN  std_logic;
      WR_PULSE : IN  std_logic;  -- one pulse writes one word, regardless of pulse duration
      FULL     : OUT std_logic;
      -- output
      SCLK     : OUT std_logic;
      DOUT     : OUT std_logic;
      SYNCn    : OUT std_logic
    );
  END COMPONENT;
  ---------------------------------------------> shiftreg driver for DAC8568  
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
  ---------------------------------------------< topmetal_analog_scan_diff
  COMPONENT topmetal_analog_scan_diff 
    GENERIC (
      ROWS          : positive := 45;     -- number of ROWS in the array
      COLS          : positive := 216;     -- number of COLS in the ARRAY
      CLK_DIV_WIDTH : positive := 16;
      CLK_DIV_WLOG2 : positive := 4;
      CONFIG_WIDTH  : positive := 16
    );
    PORT (
      CLK           : IN  std_logic;      -- clock, TM_CLK_S is derived from this one
      RESET         : IN  std_logic;      -- reset
      -- data input for writing to in-chip SRAM
      MEM_CLK       : IN  std_logic;      -- connect to control_interface
      MEM_WE        : IN  std_logic;
      MEM_ADDR      : IN  std_logic_vector(31 DOWNTO 0);
      MEM_DIN       : IN  std_logic_vector(31 DOWNTO 0);
      SRAM_WR_START : IN  std_logic;  -- 1 MEM_CLK wide pulse to initiate in-chip SRAM write
      -- configuration
      CLK_DIV       : IN  std_logic_vector(CLK_DIV_WLOG2-1 DOWNTO 0);  -- log2(CLK_DIV_WIDTH), CLK/(2**CLK_DIV)
      WR_CLK_DIV    : IN  std_logic_vector(CLK_DIV_WLOG2-1 DOWNTO 0);
      STOP_ADDR     : IN  std_logic_vector(CONFIG_WIDTH-1 DOWNTO 0);  --MSB enables
      TRIGGER_RATE  : IN  std_logic_vector(CONFIG_WIDTH-1 DOWNTO 0);  --trigger every () frames
      TRIGGER_DELAY : IN  std_logic_vector(CONFIG_WIDTH-1 DOWNTO 0);
      -- input
      MARKER_A      : IN  std_logic;
      -- output
      TRIGGER_OUT_P : OUT std_logic;
      TRIGGER_OUT_N : OUT std_logic;
      --
      SRAM_D0_P     : OUT std_logic;
      SRAM_D0_N     : OUT std_logic;
      SRAM_D1_P     : OUT std_logic;
      SRAM_D1_N     : OUT std_logic;
      SRAM_D2_P     : OUT std_logic;
      SRAM_D2_N     : OUT std_logic;
      SRAM_D3_P     : OUT std_logic;
      SRAM_D3_N     : OUT std_logic;
      --
      SRAM_WE_P     : OUT std_logic;
      SRAM_WE_N     : OUT std_logic;
      TM_RST_P      : OUT std_logic;      -- digital reset
      TM_RST_N      : OUT std_logic;      -- digital reset
      TM_CLK_S_P    : OUT std_logic;
      TM_CLK_S_N    : OUT std_logic;
      TM_RST_S_P    : OUT std_logic;
      TM_RST_S_N    : OUT std_logic;
      TM_START_S_P  : OUT std_logic;
      TM_START_S_N  : OUT std_logic;
      TM_SPEAK_S_P  : OUT std_logic;
      TM_SPEAK_S_N  : OUT std_logic
    );
  END COMPONENT;
  ---------------------------------------------> topmetal_analog_scan_diff
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
  SIGNAL control_data_fifo_q               : std_logic_vector(31 DOWNTO 0);
  SIGNAL control_data_fifo_empty           : std_logic;
  SIGNAL control_data_fifo_rdreq           : std_logic;
  SIGNAL control_data_fifo_rdclk           : std_logic;
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
  ---------------------------------------------< TOP_SR
  SIGNAL div                               : std_logic_vector(5 DOWNTO 0);
  SIGNAL din                               : std_logic_vector(15 DOWNTO 0);
  SIGNAL clk_sr_contr                      : std_logic;
  SIGNAL fifo_q                            : std_logic_vector(35 DOWNTO 0);
  ---------------------------------------------> TOP_SR
  ---------------------------------------------< PULSE_SYNCHRONISE
  SIGNAL pulse_in                          : std_logic;
  SIGNAL clk_out                           : std_logic;
  SIGNAL pulse_out                         : std_logic;
  ---------------------------------------------> PULSE_SYNCHRONISE
  ---------------------------------------------< shiftreg driver for DAC8568
  SIGNAL spi_sclk                          : std_logic;
  SIGNAL spi_data                          : std_logic;
  SIGNAL spi_sync_n                        : std_logic;
  SIGNAL spi_sync_n1                       : std_logic;
  SIGNAL spi_sync_n2                       : std_logic;
  ---------------------------------------------> shiftreg driver for DAC8568  
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
  ---------------------------------------------< topmetal_analog_scan_diff
  SIGNAL  SRAM_WR_START : std_logic;  -- 1 MEM_CLK wide pulse to initiate in-chip SRAM write
  -- configuration
  SIGNAL  TM_CLK_DIV    : std_logic_vector(3 DOWNTO 0);  -- log2(CLK_DIV_WIDTH), CLK/(2**CLK_DIV)
  SIGNAL  WR_CLK_DIV    : std_logic_vector(3 DOWNTO 0);
  SIGNAL  STOP_ADDR     : std_logic_vector(15 DOWNTO 0);  --MSB enables
  SIGNAL  TRIGGER_RATE  : std_logic_vector(15 DOWNTO 0);  --trigger every () frames
  SIGNAL  TRIGGER_DELAY : std_logic_vector(15 DOWNTO 0);
  ---------------------------------------------> tometal_analog_scan_diff

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
      DATA_FIFO_Q     => control_data_fifo_q,
      DATA_FIFO_EMPTY => control_data_fifo_empty,
      DATA_FIFO_RDREQ => control_data_fifo_rdreq,
      DATA_FIFO_RDCLK => control_data_fifo_rdclk
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

  PROCESS (sgmii125_clk, reset) IS
    VARIABLE led_cnt : unsigned(25 DOWNTO 0) := (OTHERS => '0');
  BEGIN  -- PROCESS
    IF reset = '1' THEN                   -- asynchronous reset (active high)
      led_cnt := (OTHERS => '0');
    ELSIF rising_edge(sgmii125_clk) THEN  -- rising clock edge
      led_cnt                     := led_cnt + 1;
      usr_data_output(3 DOWNTO 2) <= std_logic_vector(led_cnt(25-1 DOWNTO 23));
    END IF;
  END PROCESS;

  usr_data_output(7 DOWNTO 4) <= gig_eth_status(16) & gig_eth_status(7) & gig_eth_status(3 DOWNTO 2);

  led_obufs : FOR i IN 0 TO 7 GENERATE
    led_obuf : OBUF
      PORT MAP (
        I => usr_data_output(i),
        O => LED8Bit(i)
      );
  END GENERATE led_obufs;

  ---------------------------------------------< TOP_SR
  div <= config_reg(21 DOWNTO 16);
  din <= config_reg(15 DOWNTO 0);
  control_data_fifo_q <= fifo_q(31 DOWNTO 0);
  Top_SR_0 : Top_SR
    GENERIC MAP (
      WIDTH           => 170,
      CNT_WIDTH       => 8,
      DIV_WIDTH       => 6,
      COUNT_WIDTH     => 64,
      VALID_WIDTH     => 32,
      NUM_WIDTH       => 4,
      FIFO_WIDTH      => 36,
      SHIFT_DIRECTION => 1,
      READ_TRIG_SRC   => 0,
      READ_DELAY      => 1
    )
    PORT MAP (
      clk_in     => clk_100MHz,
      rst        => reset,
      start      => pulse_out,
      wr_en      => pulse_reg(3),
      din        => din,
      data_in_p  => FMC_HPC_LA_P(20),
      data_in_n  => FMC_HPC_LA_N(20),
      div        => div,
      fifo_rd_en => control_data_fifo_rdreq,
      clk        => clk_sr_contr,
      clk_sr_p   => FMC_HPC_LA_P(18),
      clk_sr_n   => FMC_HPC_LA_N(18),
      data_out_p => FMC_HPC_LA_P(17),
      data_out_n => FMC_HPC_LA_N(17),
      load_sr_p  => FMC_HPC_LA_P(19),
      load_sr_n  => FMC_HPC_LA_N(19),
      fifo_empty => control_data_fifo_empty,
      fifo_q     => fifo_q
    );
  ---------------------------------------------> TOP_SR
  ---------------------------------------------< PULSE_SYNCHRONISE
  pulse_in <= pulse_reg(0);
  pulse_synchronise_0 : pulse_synchronise
    PORT MAP (
      pulse_in  => pulse_in,
      clk_in    => control_clk,
      clk_out   => clk_sr_contr,
      rst       => reset,
      pulse_out => pulse_out
    );
  ---------------------------------------------> PULSE_SYNCHRONISE
  ---------------------------------------------< shiftreg driver for DAC8568
  spi_sync_n1 <= spi_sync_n WHEN config_reg(16) = '0' ELSE '1';
  spi_sync_n2 <= spi_sync_n WHEN config_reg(16) = '1' ELSE '1';   
  dac8568_inst : fifo2shiftreg
    GENERIC MAP (
      WIDTH   => 32,                    -- parallel data width
      CLK_DIV => 2                      -- SCLK freq is CLK / 2**(CLK_DIV+1)
    )
    PORT MAP (
      CLK      => control_clk,          -- clock
      RESET    => reset,                -- reset
      -- input data interface
      WR_CLK   => control_clk,          -- FIFO write clock
      DIN      => config_reg(15 DOWNTO 0),
      WR_EN    => '0',
      WR_PULSE => pulse_reg(1),  -- one pulse writes one word, regardless of pulse duration
      FULL     => OPEN,
      -- output
      SCLK     => spi_sclk,
      DOUT     => spi_data,
      SYNCn    => spi_sync_n
    );
  spi_sclk_obufds_inst : OBUFDS
    GENERIC MAP (
      IOSTANDARD => "LVDS"
    )
    PORT MAP (
      O  => FMC_HPC_LA_P(13),  -- Diff_p output (connect directly to top-level port)
      OB => FMC_HPC_LA_N(13),  -- Diff_n output (connect directly to top-level port)
      I  => spi_sclk
    );
  spi_data_obufds_inst : OBUFDS
    GENERIC MAP (
      IOSTANDARD => "LVDS"
    )
    PORT MAP (
      O  => FMC_HPC_LA_P(14),  -- Diff_p output (connect directly to top-level port)
      OB => FMC_HPC_LA_N(14),  -- Diff_n output (connect directly to top-level port)
      I  => spi_data
    );
  spi_sync_n1_obufds_inst : OBUFDS
    GENERIC MAP (
      IOSTANDARD => "LVDS"
    )
    PORT MAP (
      O  => FMC_HPC_LA_P(11),  -- Diff_p output (connect directly to top-level port)
      OB => FMC_HPC_LA_N(11),  -- Diff_n output (connect directly to top-level port)
      I  => spi_sync_n1
    );
  spi_sync_n2_obufds_inst : OBUFDS
    GENERIC MAP (
      IOSTANDARD => "LVDS"
    )
    PORT MAP (
      O  => FMC_HPC_LA_P(12),  -- Diff_p output (connect directly to top-level port)
      OB => FMC_HPC_LA_N(12),  -- Diff_n output (connect directly to top-level port)
      I  => spi_sync_n2
    );
  ---------------------------------------------> shiftreg driver for DAC8568
  ---------------------------------------------< topmetal_analog_scan_diff
  SRAM_WR_START <= pulse_reg(2);
  TM_CLK_DIV <= config_reg(179 DOWNTO 176);
  WR_CLK_DIV <= config_reg(183 DOWNTO 180);
  STOP_ADDR <= config_reg(207 DOWNTO 192);
  TRIGGER_RATE <= config_reg(223 DOWNTO 208); 
  TRIGGER_DELAY <= config_reg(239 DOWNTO 224);
  topmetal_analog_scan_diff_inst : topmetal_analog_scan_diff
    GENERIC MAP(
      ROWS  =>  45,     -- number of ROWS in the array
      COLS  => 216,     -- number of COLS in the ARRAY
      CLK_DIV_WIDTH => 16,
      CLK_DIV_WLOG2 => 4,
      CONFIG_WIDTH  => 16
    )
    PORT MAP (
      CLK           => control_clk,     -- clock, TM_CLK_S is derived from this one
      RESET         => reset,           -- reset
      -- data input for writing to in-chip SRAM
      MEM_CLK       => control_clk,     -- connect to control_interface
      MEM_WE        => control_mem_we,
      MEM_ADDR      => control_mem_addr,
      MEM_DIN       => control_mem_din,
      SRAM_WR_START => SRAM_WR_START, -- 1 MEM_CLK wide pulse to initiate in-chip SRAM write
      -- configuration
      CLK_DIV       => TM_CLK_DIV, -- log2(CLK_DIV_WIDTH), CLK/(2**CLK_DIV)
      WR_CLK_DIV    => WR_CLK_DIV,
      STOP_ADDR     => STOP_ADDR,--MSB enables
      TRIGGER_RATE  => TRIGGER_RATE,--trigger every () frames
      TRIGGER_DELAY => TRIGGER_DELAY,
      -- input
      MARKER_A      => '0',
      -- output
      --TRIGGER_OUT_P => 
      --TRIGGER_OUT_N => 
      --
      SRAM_D0_P     => FMC_HPC_LA_P(21),
      SRAM_D0_N     => FMC_HPC_LA_N(21),
      SRAM_D1_P     => FMC_HPC_LA_P(22),
      SRAM_D1_N     => FMC_HPC_LA_N(22),
      SRAM_D2_P     => FMC_HPC_LA_P(23),
      SRAM_D2_N     => FMC_HPC_LA_N(23),
      SRAM_D3_P     => FMC_HPC_LA_P(24),
      SRAM_D3_N     => FMC_HPC_LA_N(24),
      --
      SRAM_WE_P     => FMC_HPC_LA_P(25),
      SRAM_WE_N     => FMC_HPC_LA_N(25),
      --TM_RST_P      => FMC_HPC_LA_P    -- digital reset
      --TM_RST_N      => FMC_HPC_LA_N    -- digital reset
      TM_CLK_S_P    => FMC_HPC_CLK1_M2C_P,
      TM_CLK_S_N    => FMC_HPC_CLK1_M2C_N,
      TM_RST_S_P    => FMC_HPC_LA_P(26),
      TM_RST_S_N    => FMC_HPC_LA_N(26),
      TM_START_S_P  => FMC_HPC_LA_P(27),
      TM_START_S_N  => FMC_HPC_LA_N(27),
      TM_SPEAK_S_P  => FMC_HPC_LA_P(28),
      TM_SPEAK_S_N  => FMC_HPC_LA_N(28)
   );
  ---------------------------------------------> topmetal_analog_scan_diff

END Behavioral;
