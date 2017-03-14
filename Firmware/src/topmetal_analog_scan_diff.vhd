--------------------------------------------------------------------------------
--! @file topmetal_analog_scan.vhd
--! @brief Generate appropriate signals for driving the analog scan of Topmetal array.
--! @author Yuan Mei
--!
--! The bram_sdp_w32r4 must have read latency of 1 (select no register on output).
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

ENTITY topmetal_analog_scan_diff IS
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
    STOP_CLK_S    : IN  std_logic;  -- 1: stop TM_CLK_S, 0: run TM_CLK_S
    KEEP_WE       : IN  std_logic;  -- 1: SRAM_WE keep high in writing mode, 0: SRAM_WE runs in writing mode
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
END topmetal_analog_scan_diff;

ARCHITECTURE Behavioral OF topmetal_analog_scan_diff IS
-- components
  COMPONENT topmetal_analog_scan IS
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
      STOP_CLK_S    : IN  std_logic;  -- 1: stop TM_CLK_S, 0: run TM_CLK_S
      KEEP_WE       : IN  std_logic;  -- 1: SRAM_WE keep high in writing mode, 0: SRAM_WE runs in writing mode
      -- input
      MARKER_A      : IN  std_logic;
      -- output
      TRIGGER_OUT     :OUT std_logic;
      --
      SRAM_D          :OUT std_logic_vector(3 DOWNTO 0);
      SRAM_WE         :OUT std_logic;
      TM_RST          :OUT std_logic;      -- digital reset
      TM_CLK_S        :OUT std_logic;
      TM_RST_S        :OUT std_logic;
      TM_START_S      :OUT std_logic;
      TM_SPEAK_S      :OUT std_logic
   );
  END COMPONENT;

--signals
  ---------------------------------------------< topmetal_analog_scan
  SIGNAL TRIGGER_OUT     : std_logic;
  --
  SIGNAL SRAM_D          : std_logic_vector(3 DOWNTO 0);
  SIGNAL SRAM_WE         : std_logic;
  SIGNAL TM_RST          : std_logic;      -- digital reset
  SIGNAL TM_CLK_S        : std_logic;
  SIGNAL TM_RST_S        : std_logic;
  SIGNAL TM_START_S      : std_logic;
  SIGNAL TM_SPEAK_S      : std_logic;
  ---------------------------------------------> topmetal_analog_scan
 
BEGIN

  topmetal_analog_scan_inst : topmetal_analog_scan
   GENERIC MAP(
     ROWS  => 45,     -- number of ROWS in the array
     COLS  => 216,     -- number of COLS in the ARRAY
     CLK_DIV_WIDTH => 16,
     CLK_DIV_WLOG2 => 4,
     CONFIG_WIDTH  => 16
     )
   PORT MAP (
     CLK            => CLK,               -- clock, TM_CLK_S is derived from this one
     RESET          => RESET,  -- reset
     -- data input for writing to in-chip SRAM
     MEM_CLK        => MEM_CLK,  -- connect to control_interface
     MEM_WE         => MEM_WE,
     MEM_ADDR       => MEM_ADDR,
     MEM_DIN        => MEM_DIN,
     SRAM_WR_START  => SRAM_WR_START, -- 1 MEM_CLK wide pulse to initiate in-chip SRAM write
     -- configuration
     CLK_DIV        => CLK_DIV,-- log2(CLK_DIV_WIDTH), CLK/(2**CLK_DIV)
     WR_CLK_DIV     => WR_CLK_DIV,
     STOP_ADDR      => STOP_ADDR,--MSB enables
     TRIGGER_RATE   => TRIGGER_RATE,--trigger every () frames
     TRIGGER_DELAY  => TRIGGER_DELAY,
     STOP_CLK_S     => STOP_CLK_S,
     KEEP_WE        => KEEP_WE,
     -- input
     MARKER_A       => MARKER_A,
     -- output
     TRIGGER_OUT    => TRIGGER_OUT,
     --
     SRAM_D         => SRAM_D,
     SRAM_WE        => SRAM_WE,
     TM_RST         => TM_RST,     -- digital reset
     TM_CLK_S       => TM_CLK_S,
     TM_RST_S       => TM_RST_S,
     TM_START_S     => TM_START_S,
     TM_SPEAK_S     => TM_SPEAK_S
   );
   ---------------------------------------------< topmetal_analog_scan_diff
    OBUFDS_inst1 : OBUFDS
        PORT MAP (
          I  => TRIGGER_OUT, 
          O  => TRIGGER_OUT_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => TRIGGER_OUT_N  -- Diff_n buffer output (connect directly to top-level port)
        );
    
      OBUFDS_inst2 : OBUFDS
        PORT MAP (
          I  => SRAM_WE, 
          O  => SRAM_WE_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => SRAM_WE_N  -- Diff_n buffer output (connect directly to top-level port)
        );
    
      OBUFDS_inst3 : OBUFDS
        PORT MAP (
          I  => TM_RST, 
          O  => TM_RST_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => TM_RST_N  -- Diff_n buffer output (connect directly to top-level port)
        );
        
      OBUFDS_inst4 : OBUFDS
        PORT MAP (
          I  => TM_CLK_S, 
          O  => TM_CLK_S_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => TM_CLK_S_N  -- Diff_n buffer output (connect directly to top-level port)
        );
          
      OBUFDS_inst5 : OBUFDS
        PORT MAP (
          I  => TM_RST_S, 
          O  => TM_RST_S_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => TM_RST_S_N  -- Diff_n buffer output (connect directly to top-level port)
        ); 
            
      OBUFDS_inst6 : OBUFDS
        PORT MAP (
          I  => TM_START_S, 
          O  => TM_START_S_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => TM_START_S_N  -- Diff_n buffer output (connect directly to top-level port)
        );
              
      OBUFDS_inst7 : OBUFDS
        PORT MAP (
          I  => TM_SPEAK_S, 
          O  => TM_SPEAK_S_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => TM_SPEAK_S_N  -- Diff_n buffer output (connect directly to top-level port)
        );   
        
       OBUFDS_inst8 : OBUFDS
        PORT MAP (
          I  => SRAM_D(0), 
          O  => SRAM_D0_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => SRAM_D0_N  -- Diff_n buffer output (connect directly to top-level port)
        );   
    
       OBUFDS_inst9 : OBUFDS
        PORT MAP (
          I  => SRAM_D(1), 
          O  => SRAM_D1_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => SRAM_D1_N  -- Diff_n buffer output (connect directly to top-level port)
        ); 
     
       OBUFDS_inst10 : OBUFDS
        PORT MAP (
          I  => SRAM_D(2), 
          O  => SRAM_D2_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => SRAM_D2_N  -- Diff_n buffer output (connect directly to top-level port)
        ); 
        
       OBUFDS_inst11 : OBUFDS
        PORT MAP (
          I  => SRAM_D(3), 
          O  => SRAM_D3_P, -- Diff_p buffer output (connect directly to top-level port)
          OB => SRAM_D3_N  -- Diff_n buffer output (connect directly to top-level port)
        );         
    ---------------------------------------------> topmetal_analog_scan_diff
END Behavioral;
