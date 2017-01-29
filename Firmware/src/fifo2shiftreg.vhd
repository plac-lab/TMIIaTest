--------------------------------------------------------------------------------
--! @file fifo2shiftreg.vhd
--! @brief Writes data into FIFO, then this module pushes them OUT
--!        through serial bus (SPI).
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
    WIDTH   : positive := 32;           -- parallel data width
    CLK_DIV : natural  := 2             -- SCLK freq is CLK / 2**(CLK_DIV+1)
  );
  PORT (
    CLK      : IN  std_logic;           -- clock
    RESET    : IN  std_logic;           -- reset
    -- input data interface
    WR_CLK   : IN  std_logic;           -- FIFO write clock
    DIN      : IN  std_logic_vector(15 DOWNTO 0);
    WR_EN    : IN  std_logic;
    WR_PULSE : IN  std_logic;  -- one pulse writes one word, regardless of pulse duration
    FULL     : OUT std_logic;
    -- output
    SCLK  : OUT std_logic;
    DOUT  : OUT std_logic;
    SYNCn : OUT std_logic
  );
END fifo2shiftreg;

ARCHITECTURE Behavioral OF fifo2shiftreg IS

  COMPONENT shiftreg_drive
    GENERIC (
      WIDTH   : positive := 32;           -- parallel data width
      CLK_DIV : positive := 2             -- SCLK freq is CLK / 2**(CLK_DIV+1)
    );    
    PORT(
      CLK   : IN  std_logic;
      RESET : IN  std_logic;
      DATA  : IN  std_logic_vector(31 DOWNTO 0);
      START : IN  std_logic;
      BUSY  : OUT std_logic;
      SCLK  : OUT std_logic;
      DOUT  : OUT std_logic;
      SYNCn : OUT std_logic
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
  SIGNAL sd_start   : std_logic;
  SIGNAL sd_busy    : std_logic;
  --
  SIGNAL fifo_dout  : std_logic_vector(31 DOWNTO 0);
  SIGNAL fifo_wr_en : std_logic;
  SIGNAL fifo_rd_en : std_logic;
  SIGNAL fifo_empty : std_logic;
  --
  SIGNAL es_so      : std_logic;

BEGIN 

  sd : shiftreg_drive
    GENERIC MAP (
      WIDTH   => WIDTH,
      CLK_DIV => CLK_DIV
    )
    PORT MAP (
      CLK   => CLK,
      RESET => RESET,
      DATA  => fifo_dout(WIDTH-1 DOWNTO 0),
      START => sd_start,
      BUSY  => sd_busy,
      SCLK  => SCLK,
      DOUT  => DOUT,
      SYNCn => SYNCn
    );

  fifo : fifo16to32
    PORT MAP (
      RST    => RESET,
      WR_CLK => WR_CLK,
      RD_CLK => CLK,
      DIN    => DIN,
      WR_EN  => fifo_wr_en,
      RD_EN  => fifo_rd_en,
      DOUT   => fifo_dout,
      FULL   => FULL,
      EMPTY  => fifo_empty
    );

  sd_start   <= NOT fifo_empty;
  fifo_rd_en <= NOT sd_busy;

  es : edge_sync
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
