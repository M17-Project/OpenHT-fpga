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
-- TODO : Implement I/IQ mode for AM
--
-------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;
use work.cordic_pkg.all;
use work.apb_pkg.all;

entity APFM_demodulator is
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
    m_axis_o : out axis_in_iq_t;        -- master out, to downstream entity (data and valid)          -- Demodulated signal (tdata), valid (tvalid)
    m_axis_i : in axis_out_iq_t         -- master input, from downstream entity (ready)               -- From next entity's ready to receive flag (tready)
  );
end entity;

architecture magic of APFM_demodulator is
  signal I            : signed(20 downto 0) := (others => '0');
  signal Q            : signed(20 downto 0) := (others => '0');
  signal magnitude    : signed(15 downto 0) := (others => '0');
  signal phase        : signed(15 downto 0) := (others => '0');
  signal phase_0      : signed(15 downto 0) := (others => '0');
  signal phase_1      : signed(15 downto 0) := (others => '0');
  signal phase_o      : signed(15 downto 0) := (others => '0');
  signal iq_vld       : std_logic := '0';

  signal ready        : std_logic := '0';
  signal output_valid : std_logic := '0';
  signal cordic_busy  : std_logic;

  signal enable       : std_logic := '0';
  signal demod_mode   : std_logic_vector(1 downto 0) := (others => '0');

  type sig_state_t is (IDLE, COMPUTE, OUTPUT, DONE);
  signal sig_state    : sig_state_t := IDLE;

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

    X => I,
    Y => Q,
    Z => 21x"000000", -- not used

    X_Result => magnitude,
    Z_Result => phase
  );

  -- APB
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      s_apb_o.pready <= '0';
      s_apb_o.prdata <= (others => '0');

      if s_apb_i.PSEL(PSEL_ID) then
        if s_apb_i.PENABLE and s_apb_i.PWRITE then
          case s_apb_i.PADDR(2 downto 1) is
            when "00" => -- Mode
              enable <= s_apb_i.PWDATA(0);
              demod_mode <= s_apb_i.PWDATA(2 downto 1);
            when others =>
              null;
          end case;
        end if;

        if not s_apb_i.PENABLE then
          s_apb_o.pready <= '1';
          case s_apb_i.PADDR(2 downto 1) is
            when "00" => -- Mode
              s_apb_o.prdata(0) <= enable;
              s_apb_o.prdata(2 downto 1) <= demod_mode(1 downto 0);
            when others =>
              null;
          end case;
        end if;
      end if;
    end if;
  end process;

  -- FSM
  process(clk_i)
  begin
    if nrst_i = '0' then
      phase <= (others => '0');
      iq_vld <= '0';
    
    elsif rising_edge(clk_i) then
      ready <= '0';
      if not enable then
        -- Output the RAW signal
        m_axis_o.tdata <= s_axis_i.tdata;
        m_axis_o.tvalid <= s_axis_i.tvalid;
        m_axis_o.tstrb <= s_axis_i.tstrb;

      else
        case sig_state is
          when COMPUTE =>
            iq_vld <= '0';
            if output_valid then
              sig_state <= OUTPUT;
              m_axis_o.tvalid <= '1';
              -- Verify angle tdata(31) X (I),  tdata(15) Y (Q) of s_axis
              -- 00 -> nothing
              -- 10 -> add x"8000"
              -- 11 -> add x"8000"
              -- 01 -> nothing
              if s_axis_i.tdata(31) = '1' then
                phase_0 <= phase + x"8000";
              else
                phase_0 <= phase;
              end if;

            end if;
          
          when OUTPUT =>
          sig_state <= DONE;
            case demod_mode is
              when "00" => -- AM
                -- Output the magniutde
                m_axis_o.tdata(31 downto 16) <= std_logic_vector(magnitude);
                m_axis_o.tstrb <= x"C";
              when "01" => -- PM
                -- Output the phase
                m_axis_o.tdata(31 downto 16) <= std_logic_vector(phase);
                m_axis_o.tstrb <= x"C";
              when others => -- FM
                -- Compute the phase difference between the current and previous sample
                phase_1 <= phase_0;
                phase_o <=  phase_0-phase_1;
                -- Output the phase difference
                m_axis_o.tdata(31 downto 16) <= std_logic_vector(phase_o);
                m_axis_o.tstrb <= x"C";
            end case;

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
    end if;
  end process;
  -- Calculate I and Q, brought to quadrant 0 or 3 if I is negative
  I <= resize(signed(s_axis_i.tdata(31 downto 16)), 21) when not s_axis_i.tdata(31) else resize(-signed(s_axis_i.tdata(31 downto 16)), 21);
  Q <= resize(signed(s_axis_i.tdata(15 downto 0)), 21) when not s_axis_i.tdata(31) else resize(-signed(s_axis_i.tdata(15 downto 0)), 21);

  -- AXI Stream
  s_axis_o.tready <= ready when enable else (not m_axis_o.tvalid or m_axis_i.tready);
end architecture;