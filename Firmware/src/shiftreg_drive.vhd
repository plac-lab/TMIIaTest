--------------------------------------------------------------------------------
--! @file shiftreg_drive.vhd
--! @brief Module for driving external shift registers such as SPI devices.
--! @author Yuan Mei
--!
--! By default DOUT is driven by the rising edge of SCLK and DIN is captured
--! at falling edge of SCLK.
--! MSB is shifted out or captured first.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY shiftreg_drive IS
  GENERIC (
    DATA_WIDTH        : positive  := 32; -- parallel data width
    CLK_DIV_WIDTH     : positive  := 16;
    DELAY_AFTER_SYNCn : natural   := 0;  -- number of SCLK cycles' wait after falling edge OF SYNCn
    SCLK_IDLE_LEVEL   : std_logic := '0'; -- High or Low for SCLK when not switching
    DOUT_DRIVE_EDGE   : std_logic := '1'; -- 1/0 rising/falling edge of SCLK drives new DOUT bit
    DIN_CAPTURE_EDGE  : std_logic := '0'  -- 1/0 rising/falling edge of SCLK captures new DIN bit
  );
  PORT (
    CLK     : IN  std_logic;            -- clock
    RESET   : IN  std_logic;            -- reset
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
END shiftreg_drive;

ARCHITECTURE Behavioral OF shiftreg_drive IS

  SIGNAL sclk_buf    : std_logic;
  SIGNAL dout_buf    : std_logic;
  SIGNAL sync_n_buf  : std_logic;
  SIGNAL clk_cnt     : unsigned(CLK_DIV_WIDTH-1 DOWNTO 0);
  SIGNAL clk_cnt_p   : unsigned(CLK_DIV_WIDTH-1 DOWNTO 0);
  SIGNAL delay_cnt   : unsigned(CLK_DIV_WIDTH-1 DOWNTO 0);
  SIGNAL datain_reg  : std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
  SIGNAL datain_pos  : integer RANGE 0 TO DATA_WIDTH;
  SIGNAL dataout_reg : std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
  SIGNAL dataout_pos : integer RANGE 0 TO DATA_WIDTH;
  SIGNAL busy_buf    : std_logic;
  SIGNAL busy_prev   : std_logic;
  SIGNAL done        : std_logic;
  SIGNAL done_prev   : std_logic;
  --
  TYPE driveState_t IS (S0, S1, S2);
  SIGNAL driveState  : driveState_t;

BEGIN

  clk_proc: PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      clk_cnt <= to_unsigned(0, clk_cnt'length);
    ELSIF rising_edge(CLK) THEN
      clk_cnt <= clk_cnt + 1;
    END IF;
  END PROCESS clk_proc;
  sclk_buf <= CLK WHEN to_integer(unsigned(CLK_DIV)) = 0 ELSE
              clk_cnt(to_integer(unsigned(CLK_DIV))-1);

  PROCESS (CLK_DIV)
  BEGIN
    clk_cnt_p                                    <= (OTHERS => '0');
    clk_cnt_p((to_integer(unsigned(CLK_DIV)))+1) <= '1';
  END PROCESS;

  -- latch START and data
  PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      busy_buf   <= '0';
      busy_prev  <= '0';
      done_prev  <= '1';
      datain_reg <= (OTHERS => '0');
    ELSIF rising_edge(CLK) THEN
      busy_prev <= busy_buf;
      done_prev <= done;
      IF done = '1' THEN
        IF done_prev = '0' THEN         -- release busy on rising edge of done
          busy_buf  <= '0';
          busy_prev <= '0';
        ELSIF START = '1' THEN          -- latch START when done is stable
          busy_buf <= '1';
          IF busy_prev = '0' THEN       -- latch DATAIN on rise of busy
            datain_reg <= DATAIN;
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  dout_proc : PROCESS (sclk_buf, RESET)
  BEGIN
    IF RESET = '1' THEN
      driveState <= S0;
      sync_n_buf <= '1';
      done       <= '1';
    ELSIF (sclk_buf'event AND sclk_buf = DOUT_DRIVE_EDGE) THEN
      CASE driveState IS
        WHEN S0 =>
          sync_n_buf <= '1';
          IF busy_buf = '1' THEN
            sync_n_buf <= '0';
            done       <= '0';
            IF DELAY_AFTER_SYNCn > 0 THEN
              delay_cnt  <= to_unsigned(1, delay_cnt'length);
              driveState <= S1;
            ELSE
              dout_buf   <= datain_reg(DATA_WIDTH-1);
              datain_pos <= DATA_WIDTH - 1;
              driveState <= S2;
            END IF;
          END IF;

        WHEN S1 =>
          driveState <= S1;
          IF to_integer(delay_cnt) >= DELAY_AFTER_SYNCn THEN
            dout_buf   <= datain_reg(DATA_WIDTH-1);
            datain_pos <= DATA_WIDTH - 1;
            driveState <= S2;
          END IF;
          delay_cnt <= delay_cnt + 1;

        WHEN S2 =>
          driveState <= S2;
          IF datain_pos > 0 THEN
            dout_buf   <= datain_reg(datain_pos-1);
            datain_pos <= datain_pos - 1;
          ELSE
            sync_n_buf <= '1';
            done       <= '1';
            driveState <= S0;
          END IF;
          
        WHEN OTHERS =>
          driveState <= S0;
      END CASE;
    END IF;
  END PROCESS dout_proc;

  din_proc : PROCESS (sclk_buf, RESET)
  BEGIN
    IF RESET = '1' THEN
      dataout_pos <= DATA_WIDTH;
      dataout_reg <= (OTHERS => '0');
    ELSIF (sclk_buf'event AND sclk_buf = DIN_CAPTURE_EDGE) THEN
      IF driveState = S2 THEN
        dataout_reg(dataout_pos - 1) <= DIN;
        dataout_pos                  <= dataout_pos - 1;
      ELSE
        dataout_pos <= DATA_WIDTH;
      END IF;
    END IF;
  END PROCESS din_proc;

  -- output
  SCLK    <= sclk_buf WHEN (driveState = S2 AND dataout_pos > 0) ELSE SCLK_IDLE_LEVEL;
  SYNCn   <= sync_n_buf;                     -- half-SCLK early to remove glitch
  DOUT    <= dout_buf;
  --
  BUSY    <= busy_buf;
  DATAOUT <= dataout_reg;

END Behavioral;
