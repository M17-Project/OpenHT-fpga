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

entity fir_rational_resample is
  generic
  (
    N_TAPS : natural := 4; --!!! TAPS count must be a multiple of L
    L      : natural := 2; -- Interpolation factor
    M      : natural := 4; -- Decimation factor
    C_TAPS : taps_mod_t := (x"1000", x"1000", x"1000", x"1000"); -- TAPS value
    C_OUT_SHIFT : natural
  );
  port
  (
    clk_i        : in std_logic;
    s_axis_mod_i : in axis_in_mod_t;
    s_axis_mod_o : out axis_out_mod_t;
    m_axis_mod_o : out axis_in_mod_t := (tdata => (others => '0'), tvalid => '0');
    m_axis_mod_i : in axis_out_mod_t
  );
end entity fir_rational_resample;

architecture rtl of fir_rational_resample is
    constant C_BUFFER_SIZE : natural := N_TAPS / L;

    type interp_state_t is (IDLE, START_COMPUTE, FIR_COMPUTE, OUTPUT_DATA_1, OUTPUT_DATA_2);
    signal interp_state : interp_state_t := IDLE;
    signal interp_round : unsigned(3 downto 0) := (others => '0');
    signal decimation_round : unsigned(3 downto 0) := (others => '0');
    signal tap_addr    : unsigned(log2up(N_TAPS)-1 downto 0) := (others => '0');
    signal data_counter : unsigned(log2up(C_BUFFER_SIZE)-1 downto 0) := (others => '0');

    signal accumulator : signed(39 downto 0) := (others => '0');
    signal accumulate_0 : std_logic := '0';
    signal accumulate_1 : std_logic := '0';

    signal coeff_data : signed(15 downto 0) := (others => '0');
    signal buffer_rddata : signed(15 downto 0) := (others => '0');

    signal multiply_out : signed(31 downto 0);

    type buffer_data_t is array (0 to 2**log2up(C_BUFFER_SIZE)-1) of signed(15 downto 0);
    signal buffer_data : buffer_data_t := (others => (others => '0'));
    signal buffer_wrptr : unsigned(log2up(C_BUFFER_SIZE)-1 downto 0) := (others => '0');
    signal round_rdptr : unsigned(log2up(C_BUFFER_SIZE)-1 downto 0) := (others => '0');
    signal buffer_rdptr : unsigned(log2up(C_BUFFER_SIZE)-1 downto 0) := (others => '0');

begin

    assert N_TAPS mod L = 0 report "Taps count must be a multiple of L" severity error;
    assert C_TAPS'length = N_TAPS report "Taps not the same size as the declared number" severity error;

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            -- Write data
            if s_axis_mod_i.tvalid and s_axis_mod_o.tready then
                buffer_data(to_integer(buffer_wrptr)) <= signed(s_axis_mod_i.tdata);
                buffer_wrptr <= buffer_wrptr + 1;
                round_rdptr <= buffer_wrptr;
            end if;

            buffer_rddata <= buffer_data(to_integer(buffer_rdptr));
            coeff_data <= C_TAPS(to_integer(tap_addr));
        end if;
    end process;

    multiply_out <= coeff_data * buffer_rddata;

    process (clk_i)
    begin
        if rising_edge(clk_i) then
        s_axis_mod_o.tready <= '0';
        accumulate_1 <= accumulate_0;

        if accumulate_1 then
            accumulator <= accumulator + multiply_out;
        end if;

        case interp_state is
            when START_COMPUTE =>
                data_counter <= (others => '0');
                buffer_rdptr <= round_rdptr;
                interp_state <= FIR_COMPUTE;

            when FIR_COMPUTE =>
                accumulate_0 <= '1'; -- Accumulate

                -- Compute N samples FIR
                if data_counter < (N_TAPS/L) - 1 then
                    tap_addr <= tap_addr + L;
                    data_counter <= data_counter + 1;
                    buffer_rdptr <= buffer_rdptr - 1;
                else
                    interp_state <= OUTPUT_DATA_1;
                    interp_round <= interp_round + 1;
                    accumulate_0 <= '0'; -- Stop accumulation
                end if;

            when OUTPUT_DATA_1 =>
                data_counter <= (others => '0');
                buffer_rdptr <= round_rdptr;
                if decimation_round < M-1 then
                    decimation_round <= decimation_round + 1;
                else
                    decimation_round <= (others => '0');
                end if;

                if decimation_round = 0 then
                    interp_state <= OUTPUT_DATA_2;
                elsif interp_round = L then
                    interp_state <= IDLE;
                else
                    interp_state <= FIR_COMPUTE;
                end if;
                tap_addr		<= resize(interp_round, tap_addr'length);

            when OUTPUT_DATA_2 => -- Wait until acc is ready
                if not accumulate_1 then
                    m_axis_mod_o.tdata <= std_logic_vector(accumulator(39-log2up(N_TAPS)-C_OUT_SHIFT downto 39-16-log2up(N_TAPS)-C_OUT_SHIFT+1));
                    m_axis_mod_o.tvalid <= '1';
                end if;

                -- Wait for data to be accepted by downstream
                if m_axis_mod_i.tready and m_axis_mod_o.tvalid then
                    m_axis_mod_o.tvalid <= '0';
                    accumulator <= (others => '0');
                    if interp_round < L then
                        interp_state	<= FIR_COMPUTE;
                    else
                        interp_state	<= IDLE;
                    end if;
                end if;

            when others => -- IDLE
                s_axis_mod_o.tready <= m_axis_mod_i.tready;
                interp_round		<= (others => '0');
                tap_addr			<= (others => '0');
                data_counter		<= (others => '0');
                accumulate_0		<= '0';

                -- When new data comes in, start to compute
                if s_axis_mod_i.tvalid and s_axis_mod_o.tready then
                    s_axis_mod_o.tready <= '0';
                    interp_state		<= START_COMPUTE;
                end if;
        end case;
    end if;
  end process;

end architecture;
