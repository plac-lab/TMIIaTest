--------------------------------------------------------------------------------
--! @file shiftreg_drive.vhd
--! @brief Module for driving external shift registers such as SPI devices.
--! @author Yuan Mei
--!
--! By default the falling edge of SCLK is aligned at the center
--! of DOUT.  Invert SCLK ouput when necessary.  MSB of DATA is
--! shifted out first.
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
    WIDTH   : positive := 32;           -- parallel data width
    CLK_DIV : natural  := 2             -- SCLK freq is CLK / 2**(CLK_DIV+1)
  );
  PORT (
    CLK   : IN  std_logic;              -- clock
    RESET : IN  std_logic;              -- reset
    -- input data interface
    DATA  : IN  std_logic_vector(WIDTH-1 DOWNTO 0);
    START : IN  std_logic;
    BUSY  : OUT std_logic;
    -- output
    SCLK  : OUT std_logic;
    DOUT  : OUT std_logic;
    SYNCn : OUT std_logic
  );
END shiftreg_drive;

ARCHITECTURE Behavioral OF shiftreg_drive IS

  SIGNAL sclk_buf    : std_logic;
  SIGNAL dout_buf    : std_logic;
  SIGNAL sync_n_buf  : std_logic;
  SIGNAL clk_cnt     : unsigned(CLK_DIV DOWNTO 0);
  CONSTANT clk_cnt_p : unsigned(CLK_DIV DOWNTO 0) := ('1', OTHERS => '0');
  SIGNAL data_reg    : std_logic_vector(WIDTH-1 DOWNTO 0);
  SIGNAL data_pos    : integer RANGE 0 TO WIDTH;
  SIGNAL done        : std_logic;
  --
  TYPE driveState_t IS (S0, S1, S2);
  SIGNAL driveState  : driveState_t;

BEGIN 

  clk_proc: PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      clk_cnt <= to_unsigned(0, clk_cnt'length);
    ELSIF rising_edge(CLK) THEN         -- rising clock edge
      clk_cnt <= clk_cnt + 1;
    END IF;
  END PROCESS clk_proc;
  sclk_buf <= clk_cnt(CLK_DIV);

  data_proc : PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      BUSY       <= '0';
      driveState <= S0;
      sync_n_buf <= '1';
    ELSIF rising_edge(CLK) THEN
      CASE driveState IS
        WHEN S0 =>
          sync_n_buf <= '1';
          IF START = '1' THEN           -- START is level triggered
            BUSY       <= '1';
            data_reg   <= DATA;         -- register DATA
            data_pos   <= WIDTH;
            driveState <= S1;
          END IF;

        WHEN S1 =>
          driveState <= S1;
          IF clk_cnt = clk_cnt_p-1 THEN -- rising_edge of sclk
            sync_n_buf <= '0';
            IF data_pos > 0 THEN 
              dout_buf <= data_reg(data_pos-1);
              data_pos <= data_pos - 1;                
            ELSE
              sync_n_buf <= '1';
              BUSY       <= '0';
              driveState <= S0;
            END IF;
          END IF;
          
        WHEN OTHERS =>
          driveState <= S0;
      END CASE;
    END IF;
  END PROCESS data_proc;

  -- output
  SCLK  <= sclk_buf OR sync_n_buf;
  SYNCn <= sync_n_buf;
  DOUT  <= dout_buf;
  
END Behavioral;
