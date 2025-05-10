library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- UART Transmitter entity: sends 8-bit serial data over UART protocol
entity UART_TX is
  generic (
    g_CLKS_PER_BIT : integer := 217  -- Number of clock cycles per UART bit (determines baud rate)
  );
  port (
    i_Clk       : in  std_logic;                  -- System clock input
    i_TX_DV     : in  std_logic;                  -- Data valid signal to initiate transmission
    i_TX_Byte   : in  std_logic_vector(7 downto 0); -- Byte to be transmitted
    o_TX_Active : out std_logic;                  -- High when transmitter is active
    o_TX_Serial : out std_logic;                  -- Serial data output (UART TX line)
    o_TX_Done   : out std_logic                   -- High for 1 cycle when transmission is complete
  );
end UART_TX;

architecture RTL of UART_TX is

  -- State machine declaration for transmission process
  type t_SM_Main is (IDLE, TX_START_BIT, TX_DATA_BITS, TX_STOP_BIT, CLEANUP);
  signal r_SM_Main : t_SM_Main := IDLE;

  -- Clock counter to track timing for each UART bit
  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;

  -- Index to track which bit of the byte is currently being sent
  signal r_Bit_Index : integer range 0 to 7 := 0;

  -- Register to store the byte to be transmitted
  signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');

  -- Register to indicate transmission completion
  signal r_TX_Done   : std_logic := '0';
  
begin

  -- UART transmission process driven by rising edge of clock
  p_UART_TX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then

      -- Default assignment: reset TX done flag
      r_TX_Done <= '0';

      case r_SM_Main is

        -- IDLE state: wait for data valid signal to begin transmission
        when IDLE =>
          o_TX_Active <= '0';
          o_TX_Serial <= '1';  -- UART idle line is high
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;

          if i_TX_DV = '1' then
            r_TX_Data <= i_TX_Byte;       -- Latch input byte
            r_SM_Main <= TX_START_BIT;    -- Transition to start bit state
          else
            r_SM_Main <= IDLE;            -- Remain in idle
          end if;

        -- TX_START_BIT state: transmit the start bit (logic 0)
        when TX_START_BIT =>
          o_TX_Active <= '1';
          o_TX_Serial <= '0';

          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;  -- Wait full bit duration
            r_SM_Main   <= TX_START_BIT;
          else
            r_Clk_Count <= 0;
            r_SM_Main   <= TX_DATA_BITS;    -- Move to data bits
          end if;

        -- TX_DATA_BITS state: transmit each bit of the byte (LSB first)
        when TX_DATA_BITS =>
          o_TX_Serial <= r_TX_Data(r_Bit_Index);  -- Send current bit

          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= TX_DATA_BITS;
          else
            r_Clk_Count <= 0;

            if r_Bit_Index < 7 then
              r_Bit_Index <= r_Bit_Index + 1;  -- Move to next bit
              r_SM_Main   <= TX_DATA_BITS;
            else
              r_Bit_Index <= 0;
              r_SM_Main   <= TX_STOP_BIT;     -- All bits sent; go to stop bit
            end if;
          end if;

        -- TX_STOP_BIT state: transmit stop bit (logic 1)
        when TX_STOP_BIT =>
          o_TX_Serial <= '1';

          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= TX_STOP_BIT;
          else
            r_TX_Done   <= '1';    -- Flag transmission complete
            r_Clk_Count <= 0;
            r_SM_Main   <= CLEANUP; -- One final cleanup cycle
          end if;

        -- CLEANUP state: deactivate transmitter and return to IDLE
        when CLEANUP =>
          o_TX_Active <= '0';
          r_SM_Main   <= IDLE;

        -- Default case: fallback to IDLE on undefined state
        when others =>
          r_SM_Main <= IDLE;

      end case;
    end if;
  end process p_UART_TX;

  -- Connect internal done signal to output port
  o_TX_Done <= r_TX_Done;
  
end RTL;
