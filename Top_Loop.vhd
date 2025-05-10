library ieee;
use ieee.std_logic_1164.all;

-- Top-level entity for UART loopback system with dual 7-segment display output
entity Top_Loop is
  port (
    i_Clk         : in std_logic;   -- System clock (25 MHz)

    -- UART interface
    i_UART_RX     : in  std_logic;  -- UART RX line (serial input)
    o_UART_TX     : out std_logic;  -- UART TX line (serial output)

    -- 7-segment display outputs for two digits (upper and lower)
    o_Segment1_A  : out std_logic;
    o_Segment1_B  : out std_logic;
    o_Segment1_C  : out std_logic;
    o_Segment1_D  : out std_logic;
    o_Segment1_E  : out std_logic;
    o_Segment1_F  : out std_logic;
    o_Segment1_G  : out std_logic;

    o_Segment2_A  : out std_logic;
    o_Segment2_B  : out std_logic;
    o_Segment2_C  : out std_logic;
    o_Segment2_D  : out std_logic;
    o_Segment2_E  : out std_logic;
    o_Segment2_F  : out std_logic;
    o_Segment2_G  : out std_logic
  );
end entity Top_Loop;

architecture RTL of Top_Loop is

  -- UART communication signals
  signal w_RX_DV     : std_logic;                     -- Data valid signal from UART RX
  signal w_RX_Byte   : std_logic_vector(7 downto 0);  -- Received 8-bit data from UART RX
  signal w_TX_Active : std_logic;                     -- TX module active flag
  signal w_TX_Serial : std_logic;                     -- UART serial output from TX

  -- Signals for internal 7-segment wiring (before inverting)
  signal w_Segment1_A, w_Segment2_A : std_logic;
  signal w_Segment1_B, w_Segment2_B : std_logic;
  signal w_Segment1_C, w_Segment2_C : std_logic;
  signal w_Segment1_D, w_Segment2_D : std_logic;
  signal w_Segment1_E, w_Segment2_E : std_logic;
  signal w_Segment1_F, w_Segment2_F : std_logic;
  signal w_Segment1_G, w_Segment2_G : std_logic;

begin

  -- Instantiate UART receiver
  -- Decodes incoming serial data to 8-bit value when valid
  UART_RX_Inst : entity work.UART_RX
    generic map (
      g_CLKS_PER_BIT => 217  -- Baud rate configuration: 25 MHz / 115200 ≈ 217
    )
    port map (
      i_Clk       => i_Clk,
      i_RX_Serial => i_UART_RX,
      o_RX_DV     => w_RX_DV,
      o_RX_Byte   => w_RX_Byte
    );

  -- Instantiate UART transmitter
  -- Loops back received byte immediately on TX line
  UART_TX_Inst : entity work.UART_TX
    generic map (
      g_CLKS_PER_BIT => 217
    )
    port map (
      i_Clk       => i_Clk,
      i_TX_DV     => w_RX_DV,       -- Trigger TX when RX receives valid data
      i_TX_Byte   => w_RX_Byte,     -- Transmit received byte
      o_TX_Active => w_TX_Active,
      o_TX_Serial => w_TX_Serial,
      o_TX_Done   => open           -- TX done flag not used in this design
    );

  -- Drive UART TX line: output TX data when active, else keep high (idle)
  o_UART_TX <= w_TX_Serial when w_TX_Active = '1' else '1';

  -- Convert upper nibble (4 MSBs) of received byte to 7-segment code
  SevenSeg1_Inst : entity work.Binary_To_7Segment
    port map (
      i_Clk         => i_Clk,
      i_Binary_Num  => w_RX_Byte(7 downto 4),
      o_Segment_A   => w_Segment1_A,
      o_Segment_B   => w_Segment1_B,
      o_Segment_C   => w_Segment1_C,
      o_Segment_D   => w_Segment1_D,
      o_Segment_E   => w_Segment1_E,
      o_Segment_F   => w_Segment1_F,
      o_Segment_G   => w_Segment1_G
    );

  -- Invert segment outputs for active-low 7-segment display (upper digit)
  o_Segment1_A <= not w_Segment1_A;
  o_Segment1_B <= not w_Segment1_B;
  o_Segment1_C <= not w_Segment1_C;
  o_Segment1_D <= not w_Segment1_D;
  o_Segment1_E <= not w_Segment1_E;
  o_Segment1_F <= not w_Segment1_F;
  o_Segment1_G <= not w_Segment1_G;

  -- Convert lower nibble (4 LSBs) of received byte to 7-segment code
  SevenSeg2_Inst : entity work.Binary_To_7Segment
    port map (
      i_Clk         => i_Clk,
      i_Binary_Num  => w_RX_Byte(3 downto 0),
      o_Segment_A   => w_Segment2_A,
      o_Segment_B   => w_Segment2_B,
      o_Segment_C   => w_Segment2_C,
      o_Segment_D   => w_Segment2_D,
      o_Segment_E   => w_Segment2_E,
      o_Segment_F   => w_Segment2_F,
      o_Segment_G   => w_Segment2_G
    );

  -- Invert segment outputs for active-low 7-segment display (lower digit)
  o_Segment2_A <= not w_Segment2_A;
  o_Segment2_B <= not w_Segment2_B;
  o_Segment2_C <= not w_Segment2_C;
  o_Segment2_D <= not w_Segment2_D;
  o_Segment2_E <= not w_Segment2_E;
  o_Segment2_F <= not w_Segment2_F;
  o_Segment2_G <= not w_Segment2_G;

end architecture RTL;
