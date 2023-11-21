-------------------------------------------------------------
-- Complex frequency demodulator
--
-- Takes in a 32bit IQ signal stream (16bis I, 16bit Q) and outputs
-- the demodulated signal (AM, PM or FM) as a 16bit stream.
--
--
-- Frédéric Druppel, ON4PFD, fredcorp.cc
-- Sebastien, ON4SEB
-- M17 Project
-- November 2023
--
-- TODO : Implement AM and PM demodulation
-- TODO : Implement mode selector (AM, PM, FM)
-- TODO : Add APB interface
-- TODO : Implement I/IQ mode for AM
-- TODO : Normalise phase angle from -pi to pi
--
-------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;
use work.cordic_pkg.all;

entity FM_demodulator is
  port (
    clk_i   : in std_logic;             -- Clock, from upstream
    nrst_i : in std_logic;              -- Reset, from upstream

    s_axis_o : out axis_out_iq_t;       -- slave out, to upstream entity (ready)                      -- This entity ready to receive flag (tready)
    s_axis_i : in axis_in_iq_t;         -- slave in, from upstream entity (data and valid)            -- IQ signal (tdata), valid (tvalid)
    m_axis_o : out axis_in_mod_t;       -- master out, to downstream entity (data and valid)          -- Demodulated signal (tdata), valid (tvalid)
    m_axis_i : in axis_out_mod_t        -- master input, from downstream entity (ready)               -- From next entity's ready to receive flag (tready)
  );
end entity;

architecture magic of FM_demodulator is
  signal phase	: signed(20 downto 0) := (others => '0');
  signal phase_1	: signed(20 downto 0) := (others => '0');
  signal iq_vld : std_logic := '0';

  signal ready : std_logic := '0';
  signal output_valid : std_logic := '0';
  signal cordic_busy : std_logic;

  type sig_state_t is (IDLE, COMPUTE, DONE);
  signal sig_state : sig_state_t := IDLE;

begin
  -- Find the phase of the IQ signal with the CORDIC's arctan function
  -- Ø = arctan(Q/I)

  -- CORDIC
  arctan : entity work.cordic_sincos generic map( -- Same as cordic_sincos
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

    X => to_signed(s_axis_i.tdata(31 downto 16), 21), -- I
    Y => abs(to_signed(s_axis_i.tdata(15 downto 0), 21)), -- Q
    Z => 21x"000000", -- not used

    std_logic_vector(Z_Result) => phase
  );

  -- FSM
  process(clk_i)
  begin
    if nrst_i = '0' then
      phase <= (others => '0');
      iq_vld <= '0';
    
    elsif rising_edge(clk_i) then
      ready <= '0';
      case sig_state is
        when COMPUTE =>
          iq_vld <= '0';
          if output_valid then
            sig_state <= DONE;
            m_axis_o.tvalid <= '1';

            -- FM demod only at the moment

            -- Compute the phase difference between the current and previous sample
            phase_1 <= phase;
            phase <=  phase_1-phase;

            -- Output the phase difference
            m_axis_o.tdata <= std_logic_vector(phase);  -- TODO : Convert to 16bit


          end if;

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

  -- AXI Stream
  s_axis_o.tready <= ready;
end architecture;