-------------------------------------------------------------
-- Mod interpolator
-- Number of Taps must be divisible by L
--
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- M17 Project
-- November 2023
-------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;
use work.openht_utils_pkg.all;
use work.apb_pkg.all;

-- Coeff DP 1024x16
-- Data DP 1024x16
-- Indirect access to Coeff DP
-- Number of TAPS are the same for I and Q
-- L, M
-- I, I in both channels, IQ
-- 1x1024 or 2x512 mode depending on TSTRB
-- Programmable out shift/gain tbd

entity fir_rational_resample is
  generic
  (
    PSEL_ID     : natural
  );
  port
  (
    clk_i        : in std_logic;
    s_apb_i      : in apb_in_t;
    s_apb_o     : out apb_out_t;
    s_axis_i : in axis_in_iq_t;
    s_axis_o : out axis_out_iq_t;
    m_axis_o : out axis_in_iq_t := ((others => '0'), (others => '0'), '0');
    m_axis_i : in axis_out_iq_t
  );
end entity fir_rational_resample;

architecture rtl of fir_rational_resample is
  constant C_BUFFER_SIZE : natural := 1024;

  type interp_state_t is (IDLE, SETUP_INTERPOLATE, SETUP_DECIMATE, FIR_COMPUTE, OUTPUT_DATA);
  signal interp_state     : interp_state_t                                   := IDLE;
  signal interp_round     : unsigned(3 downto 0)                             := (others => '0');
  signal decimation_round : unsigned(3 downto 0)                             := (others => '0');
  signal tap_addr         : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');
  signal remaining_taps        : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');
  signal data_counter     : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');

  signal accumulator_i  : signed(41 downto 0) := (others => '0');
  signal accumulator_q  : signed(41 downto 0) := (others => '0');
  signal accumulate_0 : std_logic := '0';
  signal accumulate_1 : std_logic := '0';

  signal multiply_out_i : signed(31 downto 0);
  signal multiply_out_q : signed(31 downto 0);

  signal buffer_rd_addr : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');

  signal L             : unsigned(3 downto 0) := (others => '0');
  signal M             : unsigned(3 downto 0) := (others => '0');
  signal enabled       : std_logic            := '0';
  signal taps_cnt      : unsigned(9 downto 0) := (others => '0');
  signal duplicate_mod : std_logic := '0';

  signal fir_read_i : std_logic;
  signal fir_read_q : std_logic;
  signal taps_addr_i : unsigned(9 downto 0);
  signal taps_addr_q : unsigned(9 downto 0);
  signal mod_or_iq : std_logic; -- Mod (0) or IQ (1)

  signal buffer_wr_data : std_logic_vector(31 downto 0);
  signal buffer_wr_addr : unsigned(9 downto 0) := (others => '0');
  signal buffer_wr_addr_i : std_logic_vector(9 downto 0);
  signal buffer_wr_addr_q : std_logic_vector(9 downto 0);

  signal buffer_wr_ena : std_logic := '0';
  signal buffer_wr_enb : std_logic := '0';
  signal buffer_rd_data_i : signed(15 downto 0);
  signal buffer_rd_data_q : signed(15 downto 0);
  
  signal buffer_addr_i : std_logic_vector(9 downto 0);
  signal buffer_addr_q : std_logic_vector(9 downto 0);

  signal taps_wr_addr : unsigned(9 downto 0) := (others => '0');
  signal taps_next_wr_addr : unsigned(9 downto 0) := (others => '0');
  signal taps_wr_data : std_logic_vector(15 downto 0);
  signal taps_rd_data_i : signed(15 downto 0);
  signal taps_rd_data_q : signed(15 downto 0);
  signal taps_write : std_logic;

  signal acc_shift_i : unsigned(4 downto 0) := (others => '0');
  signal acc_shift_q : unsigned(4 downto 0) := (others => '0');

  signal accumulator_trunc_i : signed(15 downto 0);
  signal accumulator_trunc_q : signed(15 downto 0);

begin

  dpram_1024x16_taps : entity work.dpram_1024x16
  port map (
    clk => clk_i,
    ena => taps_write or fir_read_i,
    enb => fir_read_q,
    wra => taps_write,
    wrb => '0',
    addra => std_logic_vector(taps_addr_i),
    addrb => std_logic_vector(taps_addr_q),
    dina => taps_wr_data,
    dinb => X"0000",
    signed(douta) => taps_rd_data_i,
    signed(doutb) => taps_rd_data_q
  );

  -- Load Taps from port A when not enabled
  taps_addr_i <= taps_wr_addr when enabled = '0' else
    unsigned(tap_addr) when mod_or_iq = '0' else
      '0' & unsigned(tap_addr(8 downto 0));

  taps_addr_q <= unsigned(tap_addr) when mod_or_iq = '0' else
      '1' & unsigned(tap_addr(8 downto 0));

  fir_read_i <= '1' when interp_state = FIR_COMPUTE else '0';
  fir_read_q <= '1' when interp_state = FIR_COMPUTE else '0';

  dpram_1024x16_data : entity work.dpram_1024x16
  port map (
    clk => clk_i,
    ena => buffer_wr_ena or fir_read_i,
    enb => buffer_wr_enb or fir_read_q,
    wra => buffer_wr_ena,
    wrb => buffer_wr_enb,
    addra => buffer_addr_i,
    addrb => buffer_addr_q,
    dina => buffer_wr_data(31 downto 16), -- I
    dinb => buffer_wr_data(15 downto 0), -- Q or duplicated I
    signed(douta) => buffer_rd_data_i,
    signed(doutb) => buffer_rd_data_q
  );

  buffer_addr_i <= buffer_wr_addr_i when buffer_wr_ena = '1' else "0" & std_logic_vector(buffer_rd_addr(8 downto 0)) when mod_or_iq = '1' else std_logic_vector(buffer_rd_addr);
  buffer_addr_q <= buffer_wr_addr_q when buffer_wr_enb = '1' else "1" & std_logic_vector(buffer_rd_addr(8 downto 0)) when mod_or_iq = '1' else std_logic_vector(buffer_rd_addr);

  multiply_out_i <= buffer_rd_data_i * taps_rd_data_i;
  multiply_out_q <= buffer_rd_data_q * taps_rd_data_q;

  accumulator_trunc_i <= accumulator_i(accumulator_i'high - to_integer(acc_shift_i) downto accumulator_i'high - to_integer(acc_shift_i) - 16 + 1);
  accumulator_trunc_q <= accumulator_q(accumulator_q'high - to_integer(acc_shift_q) downto accumulator_q'high - to_integer(acc_shift_q) - 16 + 1);

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      accumulate_0 <= '0'; -- Stop accumulation, overriden when state = FIR_COMPUTE
      accumulate_1 <= accumulate_0;
      buffer_wr_ena <= '0';
      buffer_wr_enb <= '0';

      if accumulate_0 then
        accumulator_i <= accumulator_i + multiply_out_i;
        accumulator_q <= accumulator_q + multiply_out_q;
      end if;

      case interp_state is
        when SETUP_INTERPOLATE =>
          if interp_round < L then
            interp_state <= SETUP_DECIMATE;
            interp_round <= interp_round + 1;
          else
            interp_round <= (others => '0');
            interp_state <= IDLE;
            buffer_wr_addr <= buffer_wr_addr + 1;
          end if;
          data_counter <= (others => '0');
          buffer_rd_addr <= buffer_wr_addr;
          tap_addr     <= resize(interp_round, tap_addr'length);
          remaining_taps <= taps_cnt;

        when SETUP_DECIMATE =>
          interp_state <= FIR_COMPUTE;
          if decimation_round < M - 1 then
            decimation_round <= decimation_round + 1;
            interp_state     <= SETUP_INTERPOLATE;
          else
            decimation_round <= (others => '0');
            interp_state     <= FIR_COMPUTE;
          end if;

        when FIR_COMPUTE =>
          accumulate_0 <= '1'; -- Accumulate

          -- Compute N samples FIR
          -- Skip this output sample is decimated
          if remaining_taps > L then
            tap_addr     <= tap_addr + L;
            remaining_taps <= remaining_taps - L;
            data_counter <= data_counter + 1;
            buffer_rd_addr <= buffer_rd_addr - 1;
          else
            interp_state <= OUTPUT_DATA;
            -- Stop accumulation by after exiting this state
          end if;

        when OUTPUT_DATA => -- Wait until acc is ready
          if not accumulate_1 then
            m_axis_o.tdata(31 downto 16) <= std_logic_vector(accumulator_trunc_i);
            m_axis_o.tdata(15 downto 0)  <= std_logic_vector(accumulator_trunc_q);
            m_axis_o.tvalid <= '1';
          end if;

          -- Wait for data to be accepted by downstream
          if m_axis_i.tready and m_axis_o.tvalid then
            m_axis_o.tvalid <= '0';
            accumulator_i <= (others => '0');
            accumulator_q <= (others => '0');
            interp_state        <= SETUP_INTERPOLATE;
          end if;

        when others             => -- IDLE
          interp_round <= (others => '0');
          tap_addr     <= (others => '0');
          data_counter <= (others => '0');
          accumulate_0 <= '0';

          -- When new data comes in, start to compute
          if s_axis_i.tvalid and s_axis_o.tready then
            buffer_wr_ena <= '1';
            if not duplicate_mod then
              buffer_wr_data <= s_axis_i.tdata;
            else
              buffer_wr_data <= s_axis_i.tdata(31 downto 16) & s_axis_i.tdata(31 downto 16);
            end if;
            
            buffer_rd_addr <= buffer_wr_addr;
            
            -- Detect if we are in IQ or MOD mode
            if s_axis_i.tstrb(1 downto 0) = "11" or duplicate_mod = '1' then
              mod_or_iq <= '1';
              buffer_wr_enb <= '1';
              m_axis_o.tstrb <= X"F";
              buffer_wr_addr_i <= '0' & std_logic_vector(buffer_wr_addr(8 downto 0));
              buffer_wr_addr_q <= '1' & std_logic_vector(buffer_wr_addr(8 downto 0));
            else
              m_axis_o.tstrb <= X"C";
              mod_or_iq <= '0';
              buffer_wr_addr_i <= std_logic_vector(buffer_wr_addr);
            end if;

            interp_state <= SETUP_INTERPOLATE;
          end if;
      end case;
    end if;
  end process;

  s_axis_o.tready <= '1' when interp_state = IDLE else '0';

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      s_apb_o.pready <= '0';
      s_apb_o.prdata <= (others => '0');
      taps_write <= '0';

      if s_apb_i.PSEL(PSEL_ID) then
        if s_apb_i.PENABLE and s_apb_i.PWRITE then
          case s_apb_i.paddr(4 downto 1) is
            when "0000" => -- Control/Status REG
              enabled       <= s_apb_i.pwdata(0);
              duplicate_mod <= s_apb_i.pwdata(1);

            when "0001" => -- Taps Count REG
              if not enabled then
                taps_cnt <= unsigned(s_apb_i.pwdata(9 downto 0));
              end if;

            when "0010" => -- Interpolation (L) REG
              if not enabled then
                L <= unsigned(s_apb_i.pwdata(3 downto 0));
              end if;

            when "0011" => -- Decimation (M) REG
              if not enabled then
                M <= unsigned(s_apb_i.pwdata(3 downto 0));
              end if;

            when "0100" => -- Taps Address
              taps_next_wr_addr <= unsigned(s_apb_i.pwdata(9 downto 0));

            when "0101" => -- Taps Data
              if not enabled then
                taps_wr_data <= s_apb_i.pwdata;
                taps_next_wr_addr <= taps_next_wr_addr + 1;
                taps_wr_addr <= taps_next_wr_addr;
                taps_write <= '1';
              end if;

            when "0110" => -- I Accumulator shift
              if not enabled then
                acc_shift_i <= unsigned(s_apb_i.pwdata(4 downto 0));
              end if;

            when "0111" => -- Q Accumulator shift
              if not enabled then
                acc_shift_q <= unsigned(s_apb_i.pwdata(4 downto 0));
              end if;

            when others =>
              null;
          end case;
        end if;

        if not s_apb_i.PENABLE then
          case s_apb_i.paddr(4 downto 1) is
            when "0000" => -- Control/Status REG
              s_apb_o.prdata(0) <= enabled;
              s_apb_o.prdata(1) <= duplicate_mod;

            when "0001" => -- Taps Count REG
              s_apb_o.prdata(9 downto 0) <= std_logic_vector(taps_cnt);

            when "0010" => -- Interpolation (L) REG
              s_apb_o.prdata(3 downto 0) <= std_logic_vector(L);

            when "0011" => -- Decimation (M) REG
              s_apb_o.prdata(3 downto 0) <= std_logic_vector(M);

            when "0100" => -- Taps Address
              s_apb_o.prdata(9 downto 0) <= std_logic_vector(taps_wr_addr);

            when "0101" => -- Taps data
              null; -- No taps data readback

            when "0110" =>
              s_apb_o.prdata(4 downto 0) <= std_logic_vector(acc_shift_i);

            when "0111" =>
              s_apb_o.prdata(4 downto 0) <= std_logic_vector(acc_shift_q);

            when others =>
              null;

          end case;
          s_apb_o.pready <= '1';

        end if;

      end if;

    end if;
  end process;

end architecture;