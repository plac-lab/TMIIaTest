--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   14:39:52 01/07/2015
-- Design Name:   shiftreg_drive_tb
-- Module Name:
-- Project Name:
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: shiftreg_drive
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;

ENTITY shiftreg_drive_tb IS
END shiftreg_drive_tb;

ARCHITECTURE behavior OF shiftreg_drive_tb IS

  -- Component Declaration for the Unit Under Test (UUT)

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
      CLK     : IN  std_logic;
      RESET   : IN  std_logic;
      CLK_DIV : IN  std_logic_vector(CLK_DIV_WIDTH-1 DOWNTO 0);  -- SCLK freq is CLK / 2**(CLK_DIV)
      DATAIN  : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
      START   : IN  std_logic;
      BUSY    : OUT std_logic;
      DATAOUT : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
      SCLK    : OUT std_logic;
      DOUT    : OUT std_logic;
      SYNCn   : OUT std_logic;
      DIN     : IN  std_logic
    );
  END COMPONENT;

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

  --Inputs
  SIGNAL CLK     : std_logic                     := '0';
  SIGNAL CLK_DIV : std_logic_vector(15 DOWNTO 0) := x"0003";
  SIGNAL RESET   : std_logic                     := '0';
  SIGNAL DATAIN  : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL START   : std_logic                     := '0';
  SIGNAL DIN     : std_logic;

  --Outputs
  SIGNAL DATAOUT  : std_logic_vector(31 DOWNTO 0);
  SIGNAL BUSY     : std_logic;
  SIGNAL SCLK     : std_logic;
  SIGNAL DOUT     : std_logic;
  SIGNAL SYNCn    : std_logic;

  -- internals
  SIGNAL wr_start   : std_logic := '0';
  SIGNAL fifo_din   : std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL fifo_wr_en : std_logic;
  SIGNAL fifo_rd_en : std_logic;
  SIGNAL fifo_full  : std_logic;
  SIGNAL fifo_empty : std_logic;

  -- Clock period definitions
  CONSTANT CLK_period  : time := 10 ns;
  CONSTANT SCLK_period : time := 10 ns;

BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut : shiftreg_drive PORT MAP (
    CLK     => CLK,
    CLK_DIV => CLK_DIV,
    RESET   => RESET,
    DATAIN  => DATAIN,
    START   => START,
    BUSY    => BUSY,
    DATAOUT => DATAOUT,
    SCLK    => SCLK,
    DOUT    => DOUT,
    SYNCn   => SYNCn,
    DIN     => DIN
  );
  DIN <= DOUT;

  fifo : fifo16to32
    PORT MAP (
      RST    => RESET,
      WR_CLK => CLK,
      RD_CLK => CLK,
      DIN    => fifo_din,
      WR_EN  => fifo_wr_en,
      RD_EN  => fifo_rd_en,
      DOUT   => DATAIN,
      FULL   => fifo_full,
      EMPTY  => fifo_empty
    );

  START      <= NOT fifo_empty;
  -- rising edge of busy
  rd_es : edge_sync
    GENERIC MAP (
      EDGE => '1'  -- '1'  :  rising edge,  '0' falling edge
    )
    PORT MAP (
      RESET => RESET,
      CLK   => CLK,
      EI    => BUSY,
      SO    => fifo_rd_en
    );

  wr_es : edge_sync
    GENERIC MAP (
      EDGE => '1'  -- '1'  :  rising edge,  '0' falling edge
    )
    PORT MAP (
      RESET => RESET,
      CLK   => CLK,
      EI    => wr_start,
      SO    => fifo_wr_en
    );

  -- Clock process definitions
  CLK_process : PROCESS
  BEGIN
    CLK <= '0';
    WAIT FOR CLK_period/2;
    CLK <= '1';
    WAIT FOR CLK_period/2;
  END PROCESS;

  -- Stimulus process
  stim_proc : PROCESS
  BEGIN
    WAIT FOR 25ns;
    -- hold reset state for 80 ns.
    RESET <= '1';
    WAIT FOR 80 ns;
    RESET <= '0';
    WAIT FOR CLK_period*12;

    -- insert stimulus here
    WAIT FOR 10ps;
    fifo_din <= x"505a";
    wr_start <= '1';
    WAIT FOR CLK_period*3;
    wr_start <= '0';
    fifo_din <= x"a505";
    WAIT FOR CLK_period;
    wr_start <= '1';
    WAIT FOR CLK_period*3;
    wr_start <= '0';

    WAIT FOR 20ns;
    fifo_din <= x"abcd";
    wr_start <= '1';
    WAIT FOR CLK_period*3;
    wr_start <= '0';
    fifo_din <= x"1234";
    WAIT FOR CLK_period;
    wr_start <= '1';
    WAIT FOR CLK_period*3;
    wr_start <= '0';

    WAIT FOR 1100ns;
    fifo_din <= x"4321";
    wr_start <= '1';
    WAIT FOR CLK_period*3;
    wr_start <= '0';
    fifo_din <= x"dcba";
    WAIT FOR CLK_period;
    wr_start <= '1';
    WAIT FOR CLK_period*3;
    wr_start <= '0';

    WAIT;
  END PROCESS;

END;
