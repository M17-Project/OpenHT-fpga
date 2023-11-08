-------------------------------------------------------------
-- Mod interpolator
-- Number of Taps must be divisible by L
--
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- M17 Project
-- July 2023
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
    PSEL_ID     : natural;
    C_OUT_SHIFT : natural
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
  signal tap_count        : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');
  signal data_counter     : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');

  signal accumulator  : signed(39 downto 0) := (others => '0');
  signal accumulate_0 : std_logic           := '0';
  signal accumulate_1 : std_logic           := '0';

  signal coeff_data    : signed(15 downto 0) := (others => '0');
  signal buffer_rddata : signed(15 downto 0) := (others => '0');

  signal multiply_out : signed(31 downto 0);

  signal buffer_wrptr : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');
  signal round_rdptr  : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');
  signal buffer_rdptr : unsigned(log2up(C_BUFFER_SIZE - 1) - 1 downto 0) := (others => '0');

  signal L             : unsigned(3 downto 0) := X"3";
  signal M             : unsigned(3 downto 0) := X"1";
  signal enabled       : std_logic            := '0';
  signal taps_cnt      : unsigned(9 downto 0) := 10x"00f";
  signal duplicate_mod : std_logic;

  signal taps_addr_i : unsigned(9 downto 0);
  signal taps_addr_q : unsigned(9 downto 0);
  signal mod_or_iq : std_logic; -- Mod (0) or IQ (1)

  signal buffer_wr_data : std_logic_vector(31 downto 0);
  signal buffer_rd_data_i : signed(15 downto 0);
  signal buffer_rd_data_q : signed(15 downto 0);

  signal taps_wr_addr : unsigned(9 downto 0);
  signal taps_wr_data : std_logic_vector(15 downto 0);
  signal taps_rd_data_a : signed(15 downto 0);
  signal taps_rd_data_b : signed(15 downto 0);
  signal taps_write : std_logic;

begin

  dpram_1024x16_taps : entity work.dpram_1024x16
  port map (
    clk => clk_i,
    ena => taps_write,
    enb => '0', -- TODO Change for read
    wra => taps_write,
    wrb => '0',
    addra => std_logic_vector(taps_addr_i),
    addrb => std_logic_vector(taps_addr_q),
    dina => taps_wr_data,
    dinb => X"0000",
    signed(douta) => taps_rd_data_a,
    signed(doutb) => taps_rd_data_b
  );

  -- Load Taps from port A when not enabled
  taps_addr_i <= taps_wr_addr when enabled = '0' else
    unsigned(tap_addr) when mod_or_iq = '0' else
      '0' & unsigned(tap_addr(8 downto 0));

  taps_addr_q <= unsigned(tap_addr) when mod_or_iq = '0' else
      '1' & unsigned(tap_addr(8 downto 0));

  dpram_1024x16_data : entity work.dpram_1024x16
  port map (
    clk => clk_i,
    ena => '0',
    enb => '0',
    wra => '0',
    wrb => '0',
    addra => 10x"000",
    addrb => 10x"000",
    dina => buffer_wr_data(31 downto 16), -- I
    dinb => buffer_wr_data(15 downto 0), -- Q or duplicated I
    signed(douta) => buffer_rd_data_i,
    signed(doutb) => buffer_rd_data_q
  );

  -- process (clk_i)
  -- begin
  --   if rising_edge(clk_i) then
  --     -- Write data
  --     if s_axis_i.tvalid and s_axis_o.tready then
  --       buffer_data(to_integer(buffer_wrptr)) <= signed(s_axis_i.tdata);
  --       buffer_wrptr                          <= buffer_wrptr + 1;
  --       round_rdptr                           <= buffer_wrptr;
  --     end if;

  --     buffer_rddata <= buffer_data(to_integer(buffer_rdptr));
  --     coeff_data    <= X"0001"; -- C_TAPS(to_integer(tap_addr));
  --   end if;
  -- end process;

  multiply_out <= coeff_data * buffer_rddata;

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      accumulate_0 <= '0'; -- Stop accumulation, overriden when state = FIR_COMPUTE
      accumulate_1 <= accumulate_0;

      if accumulate_0 then
        accumulator <= accumulator + multiply_out;
      end if;

      case interp_state is
        when SETUP_INTERPOLATE =>
          if interp_round < L then
            interp_state <= SETUP_DECIMATE;
            interp_round <= interp_round + 1;
          else
            interp_round <= (others => '0');
            interp_state <= IDLE;
          end if;
          data_counter <= (others => '0');
          buffer_rdptr <= round_rdptr;
          tap_addr     <= resize(interp_round, tap_addr'length);
          tap_count    <= (others => '0');

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
          if tap_count < taps_cnt then
            tap_addr     <= tap_addr + L;
            tap_count    <= tap_count + L;
            data_counter <= data_counter + 1;
            buffer_rdptr <= buffer_rdptr - 1;
          else
            interp_state <= OUTPUT_DATA;
            -- Stop accumulation by after exiting this state
          end if;

        when OUTPUT_DATA => -- Wait until acc is ready
          if not accumulate_1 then
            -- TODO fix dynamic offset
            m_axis_o.tdata  <= std_logic_vector(accumulator(39 downto 39 - 32 + 1));
            m_axis_o.tvalid <= '1';
          end if;

          -- Wait for data to be accepted by downstream
          if m_axis_i.tready and m_axis_o.tvalid then
            m_axis_o.tvalid <= '0';
            accumulator         <= (others => '0');
            interp_state        <= SETUP_INTERPOLATE;
          end if;

        when others             => -- IDLE
          interp_round <= (others => '0');
          tap_addr     <= (others => '0');
          data_counter <= (others => '0');
          accumulate_0 <= '0';

          -- When new data comes in, start to compute
          if s_axis_i.tvalid and s_axis_o.tready then
            -- Detect if we are in IQ or MOD mode
            mod_or_iq <= '1' when s_axis_i.tstrb(1 downto 0) = "11" or duplicate_mod = '1' else '0';
            if not duplicate_mod then
              buffer_wr_data <= s_axis_i.tdata;
            else
              buffer_wr_data <= s_axis_i.tdata(31 downto 16) & s_axis_i.tdata(31 downto 16);
            end if;

            interp_state <= SETUP_INTERPOLATE;
          end if;
      end case;
    end if;
  end process;

  s_axis_o.tready <= '1' when interp_state = IDLE or m_axis_o.tvalid = '0' else
  '0';

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      s_apb_o.pready <= '0';
      s_apb_o.prdata <= (others => '0');
      taps_write <= '0';

      if s_apb_i.PSEL(PSEL_ID) then
        if s_apb_i.PENABLE and s_apb_i.PWRITE then
          case s_apb_i.paddr(3 downto 1) is
            when "000" => -- Control/Status REG
              enabled       <= s_apb_i.pwdata(0);
              duplicate_mod <= s_apb_i.pwdata(1);

            when "001" => -- Taps Count REG
              if not enabled then
                taps_cnt <= unsigned(s_apb_i.pwdata(9 downto 0));
              end if;

            when "010" => -- Interpolation (L) REG
              if not enabled then
                L <= unsigned(s_apb_i.pwdata(3 downto 0));
              end if;

            when "011" => -- Decimation (M) REG
              if not enabled then
                M <= unsigned(s_apb_i.pwdata(3 downto 0));
              end if;

            when "100" => -- Taps Address
              taps_wr_addr <= unsigned(s_apb_i.pwdata(9 downto 0));

            when "101" => -- Taps Data
              if not enabled then
                taps_wr_data <= s_apb_i.pwdata;
                taps_wr_addr <= taps_wr_addr + 1;
                taps_write <= '1';
              end if;

            when others =>
              null;
          end case;
        end if;

        if not s_apb_i.PENABLE then
          case s_apb_i.paddr(3 downto 1) is
            when "000" => -- Control/Status REG
              s_apb_o.prdata(0) <= enabled;
              s_apb_o.prdata(1) <= duplicate_mod;

            when "001" => -- Taps Count REG
              s_apb_o.prdata(9 downto 0) <= std_logic_vector(taps_cnt);

            when "010" => -- Interpolation (L) REG
              s_apb_o.prdata(3 downto 0) <= std_logic_vector(L);

            when "011" => -- Decimation (M) REG
              s_apb_o.prdata(3 downto 0) <= std_logic_vector(M);

            when "100" => -- Taps Address
              s_apb_o.prdata(9 downto 0) <= std_logic_vector(taps_wr_addr);

            when "101" => -- Taps data
              null; -- No taps data readback

            when others =>
              null;

          end case;
          s_apb_o.pready <= '1';

        end if;

      end if;

    end if;
  end process;

end architecture;