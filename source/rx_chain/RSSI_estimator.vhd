-------------------------------------------------------------
-- RSSI estimator
--
--
-- Frédéric Druppel, ON4PFD, fredcorp.cc
-- Sebastien, ON4SEB
-- M17 Project
-- November 2023
--
--
-------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;
use work.cordic_pkg.all;
use work.apb_pkg.all;

entity RSSI_estimator is
  generic  (
    PSEL_ID : natural
  );
  port (
    clk_i    : in std_logic;            -- Clock, from upstream
    nrst_i   : in std_logic;            -- Reset, from upstream

    s_apb_o  : out apb_out_t;           -- slave apb interface out, to upstream
    s_apb_i  : in apb_in_t;             -- slave apb interface in, from upstream

    s_axis_o : out axis_out_iq_t;       -- slave out, to upstream entity (ready)                      -- This entity's ready to receive flag (tready)
    s_axis_i : in axis_in_iq_t;         -- slave in, from upstream entity (data and valid)            -- IQ signal (tdata), valid (tvalid)
    m_axis_o : out axis_in_iq_t;        -- master out, to downstream entity (data and valid)          -- Signal RSSI (tdata), valid (tvalid)
    m_axis_i : in axis_out_iq_t         -- master input, from downstream entity (ready)               -- From next entity's ready to receive flag (tready)
  );
end entity;

architecture magic of RSSI_estimator is
  signal I            : signed(20 downto 0) := (others => '0');
  signal Q            : signed(20 downto 0) := (others => '0');
  signal magnitude    : signed(15 downto 0) := (others => '0');
  signal magnitude_o  : signed(15 downto 0) := (others => '0');
  signal iq_vld       : std_logic := '0';

  signal ready        : std_logic := '0';
  signal output_valid : std_logic := '0';
  signal cordic_busy  : std_logic;

  signal hold         : std_logic_vector(15 downto 0) := (others => '0');

  signal enable       : std_logic := '0';
  signal attack       : std_logic_vector(15 downto 0) := (others => '0');
  signal decay        : std_logic_vector(15 downto 0) := (others => '0');
  signal hold_config  : std_logic_vector(15 downto 0) := (others => '0');

  type sig_state_t is (IDLE, COMPUTE, OUTPUT, DONE);
  signal sig_state    : sig_state_t := IDLE;

begin
  -- CORDIC
  arctan : entity work.cordic_sincos generic map(
    SIZE => 21,
    ITERATIONS => 21,
    TRUNC_SIZE => 16,
    RESET_ACTIVE_LEVEL => '0'
    )
  port map(
    Clock => clk_i,
    Reset => nrst_i,

    Data_valid => iq_vld,
    Busy       => cordic_busy,
    Result_valid => output_valid,
    Mode => cordic_vector,

    X => I,
    Y => Q,
    Z => 21x"000000", -- not used

    std_logic_vector(X_Result) => magnitude
  );

  -- APB
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      s_apb_o.pready <= '0';
      s_apb_o.prdata <= (others => '0');

      if s_apb_i.PENABLE and s_apb_i.PWRITE then
        case s_apb_i.PADDR is
          when "00" =>
            enable <= s_apb_i.PWDATA(0);
          when "01" =>
            attack <= s_apb_i.PWDATA;
          when "10" =>
            decay <= s_apb_i.PWDATA;
          when "11" =>
            hold_config <= s_apb_i.PWDATA;
          when others =>
            null;
        end case;
      end if;

      if not s_apb_i.PENABLE then
        s_apb_o.pready <= '1';
        case s_apb_i.PADDR is
          when "01" =>
            s_apb_o.prdata <= attack;
          when "10" =>
            s_apb_o.prdata <= decay;
          when others =>
            s_apb_o.prdata <= (others => '0');
        end case;
      end if;
    end if;
  end process;

  -- FSM
  process(clk_i)
  begin
    if nrst_i = '0' then
      magnitude <= (others => '0');
      iq_vld <= '0';
    
    elsif rising_edge(clk_i) then
      ready <= '0';
      
      case sig_state is
        when COMPUTE =>
          iq_vld <= '0';
          if output_valid then
            sig_state <= OUTPUT;
            m_axis_o.tvalid <= '1';
            if magnitude > magnitude_o then
              magnitude_o <= minimum(magnitude, magnitude_o+attack);
              hold <= hold_config;
            else
              if hold > 0 then
                magnitude_o <= magnitude_o;
                hold <= hold-1;
              else
                magnitude_o <= magnitude_o-decay;
              end if;
            end if;
          end if;
        
        when OUTPUT =>
          sig_state <= DONE;
          m_axis_o.tdata(31 downto 16) <= std_logic_vector(magnitude_o);
          m_axis_o.tstrb <= x"C";

        when DONE =>
          if m_axis_i.tready and m_axis_o.tvalid then
            sig_state <= IDLE;
            m_axis_o.tvalid <= '0';
          end if;

        when others =>
          m_axis_o.tvalid <= '0';
          ready <= '1';
          if s_axis_i.tvalid and not cordic_busy then
            ready <= '0';
            iq_vld <= '1';
            sig_state <= COMPUTE;
          end if;

      end case;
    end if;
  end process;
  -- Calculate I and Q, brought to quadrant 0 or 3 if I is negative
  I <= signed(s_axis_i.tdata(31 downto 16)) when not s_axis_i.tdata(31) else -signed(s_axis_i.tdata(31 downto 16));
  Q <= signed(s_axis_i.tdata(15 downto 0)) when not s_axis_i.tdata(31) else -signed(s_axis_i.tdata(15 downto 0));

  -- AXI Stream
  s_axis_o.tready <= ready when enable else (not m_axis_o.tvalid or m_axis_i.tready);
end architecture;