--------------------------------------------------------------------------------
--! @file fifo2shiftreg.vhd
--! @brief Writes data into FIFO, then this module pushes them out
--!        through serial bus (SPI).  DIN is captured simultaneously.
--! @author Yuan Mei
--!
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY fifo2shiftreg IS
  GENERIC (
    DATA_WIDTH        : positive  := 32; -- parallel data width
    CLK_DIV_WIDTH     : positive  := 16;
    DELAY_AFTER_SYNCn : natural   := 0;  -- number of SCLK cycles' wait after falling edge OF SYNCn
    SCLK_IDLE_LEVEL   : std_logic := '0'; -- High or Low for SCLK when not switching
    DOUT_DRIVE_EDGE   : std_logic := '1'; -- 1/0 rising/falling edge of SCLK drives new DOUT bit
    DIN_CAPTURE_EDGE  : std_logic := '0'  -- 1/0 rising/falling edge of SCLK captures new DIN bit
  );
  PORT (
    CLK      : IN  std_logic;           -- clock
    RESET    : IN  std_logic;           -- reset
    -- input data interface
    WR_CLK   : IN  std_logic;           -- FIFO write clock
    DINFIFO  : IN  std_logic_vector(15 DOWNTO 0);
    WR_EN    : IN  std_logic;
    WR_PULSE : IN  std_logic;  -- one pulse writes one word, regardless of pulse duration
    FULL     : OUT std_logic;
    -- captured data
    BUSY     : OUT std_logic;
    DATAOUT  : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
    -- serial interface
    CLK_DIV  : IN  std_logic_vector(CLK_DIV_WIDTH-1 DOWNTO 0);  -- SCLK freq is CLK / 2**(CLK_DIV)
    SCLK     : OUT std_logic;
    DOUT     : OUT std_logic;
    SYNCn    : OUT std_logic;
    DIN      : IN  std_logic
  );
END fifo2shiftreg;

ARCHITECTURE Behavioral OF fifo2shiftreg IS

  COMPONENT shiftreg_drive
    GENERIC (
      DATA_WIDTH        : positive  := 32;  -- parallel data width
      CLK_DIV_WIDTH     : positive  := 16;
      DELAY_AFTER_SYNCn : natural   := 0;  -- number of SCLK cycles' wait after falling edge OF SYNCn
      SCLK_IDLE_LEVEL   : std_logic := '0';  -- High or Low for SCLK when not switching
      DOUT_DRIVE_EDGE   : std_logic := '1';  -- 1/0 rising/falling edge of SCLK drives new DOUT bit
      DIN_CAPTURE_EDGE  : std_logic := '0'  -- 1/0 rising/falling edge of SCLK captures new DIN bit
    );    
    PORT (
      CLK     : IN  std_logic;          -- clock
      RESET   : IN  std_logic;          -- reset
      -- internal data interface
      CLK_DIV : IN  std_logic_vector(CLK_DIV_WIDTH-1 DOWNTO 0);  -- SCLK freq is CLK / 2**(CLK_DIV)
      DATAIN  : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
      START   : IN  std_logic;
      BUSY    : OUT std_logic;
      DATAOUT : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
      -- external serial interface
      SCLK    : OUT std_logic;
      DOUT    : OUT std_logic;
      SYNCn   : OUT std_logic;
      DIN     : IN  std_logic
    );
  END COMPONENT;
  --
  COMPONENT edge_sync
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
  --
  COMPONENT fifo16to32
    PORT (
      RST    : IN  std_logic;
      WR_CLK : IN  std_logic;
      RD_CLK : IN  std_logic;
      DIN    : IN  std_logic_vector(15 DOWNTO 0);
      WR_EN  : IN  std_logic;
      RD_EN  : IN  std_logic;
      DOUT   : OUT std_logic_vector(31 DOWNTO 0);
      FULL   : OUT std_logic;
      EMPTY  : OUT std_logic
    );
  END COMPONENT;
  --
  SIGNAL sd_start     : std_logic;
  SIGNAL sd_busy      : std_logic;
  --
  SIGNAL fifo_dout    : std_logic_vector(31 DOWNTO 0);
  SIGNAL fifo_wr_en   : std_logic;
  SIGNAL fifo_rd_en   : std_logic;
  SIGNAL fifo_empty   : std_logic;
  --
  SIGNAL es_so        : std_logic;

BEGIN 

  sd : shiftreg_drive
    GENERIC MAP (
      DATA_WIDTH        => DATA_WIDTH,
      CLK_DIV_WIDTH     => CLK_DIV_WIDTH,
      DELAY_AFTER_SYNCn => DELAY_AFTER_SYNCn,
      SCLK_IDLE_LEVEL   => SCLK_IDLE_LEVEL,
      DOUT_DRIVE_EDGE   => DOUT_DRIVE_EDGE,
      DIN_CAPTURE_EDGE  => DIN_CAPTURE_EDGE
    )
    PORT MAP (
      CLK     => CLK,
      RESET   => RESET,
      -- internal data interface
      CLK_DIV => CLK_DIV,
      DATAIN  => fifo_dout(DATA_WIDTH-1 DOWNTO 0),
      START   => sd_start,
      BUSY    => sd_busy,
      DATAOUT => DATAOUT,
      -- external serial interface
      SCLK    => SCLK,
      DOUT    => DOUT,
      SYNCn   => SYNCn,
      DIN     => DIN
    );
  BUSY <= sd_busy;

  fifo : fifo16to32
    PORT MAP (
      RST    => RESET,
      WR_CLK => WR_CLK,
      RD_CLK => CLK,
      DIN    => DINFIFO,
      WR_EN  => fifo_wr_en,
      RD_EN  => fifo_rd_en,
      DOUT   => fifo_dout,
      FULL   => FULL,
      EMPTY  => fifo_empty
    );

  sd_start   <= NOT fifo_empty;
  -- rising edge of busy
  rd_es : edge_sync
    GENERIC MAP (
      EDGE => '1'  -- '1'  :  rising edge,  '0' falling edge
    )
    PORT MAP (
      RESET => RESET,
      CLK   => CLK,
      EI    => sd_busy,
      SO    => fifo_rd_en
    );

  wr_es : edge_sync
    GENERIC MAP (
      EDGE => '1'  -- '1'  :  rising edge,  '0' falling edge
    )
    PORT MAP (
      RESET => RESET,
      CLK   => CLK,
      EI    => WR_PULSE,
      SO    => es_so
    );
  fifo_wr_en <= es_so OR WR_EN;
  
END Behavioral;
