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
    constant C_BUFFER_SIZE : natural := 1024;

    type interp_state_t is (IDLE, SETUP_INTERPOLATE, SETUP_DECIMATE, FIR_COMPUTE, OUTPUT_DATA);
    signal interp_state : interp_state_t := IDLE;
    signal interp_round : unsigned(3 downto 0) := (others => '0');
    signal decimation_round : unsigned(3 downto 0) := (others => '0');
    signal tap_addr    : unsigned(log2up(C_BUFFER_SIZE-1)-1 downto 0) := (others => '0');
    signal tap_count : unsigned(log2up(C_BUFFER_SIZE-1)-1 downto 0) := (others => '0');
    signal data_counter : unsigned(log2up(C_BUFFER_SIZE-1)-1 downto 0) := (others => '0');

    signal accumulator : signed(39 downto 0) := (others => '0');
    signal accumulate_0 : std_logic := '0';
    signal accumulate_1 : std_logic := '0';

    signal coeff_data : signed(15 downto 0) := (others => '0');
    signal buffer_rddata : signed(15 downto 0) := (others => '0');

    signal multiply_out : signed(31 downto 0);

    type buffer_data_t is array (0 to C_BUFFER_SIZE-1) of signed(15 downto 0);
    signal buffer_data : buffer_data_t := (others => (others => '0'));
    signal buffer_wrptr : unsigned(log2up(C_BUFFER_SIZE-1)-1 downto 0) := (others => '0');
    signal round_rdptr : unsigned(log2up(C_BUFFER_SIZE-1)-1 downto 0) := (others => '0');
    signal buffer_rdptr : unsigned(log2up(C_BUFFER_SIZE-1)-1 downto 0) := (others => '0');

    signal L : unsigned(3 downto 0) := X"3";
    signal M : unsigned(3 downto 0) := X"1";
    signal enable : std_logic := '0';
    signal taps_count : unsigned(9 downto 0) := 10x"00f";
    signal taps_iq_offset : unsigned(9 downto 0) := (others => '0');

begin

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
            coeff_data <= X"0001"; -- C_TAPS(to_integer(tap_addr));
        end if;
    end process;

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
                tap_addr <= resize(interp_round, tap_addr'length);
                tap_count <= (others => '0');

            when SETUP_DECIMATE =>
                interp_state <= FIR_COMPUTE;
                if decimation_round < M-1 then
                    decimation_round <= decimation_round + 1;
                    interp_state <= SETUP_INTERPOLATE;
                else
                    decimation_round <= (others => '0');
                    interp_state <= FIR_COMPUTE;
                end if;

            when FIR_COMPUTE =>
                accumulate_0 <= '1'; -- Accumulate

                -- Compute N samples FIR
                -- Skip this output sample is decimated
                if tap_count < taps_count then
                    tap_addr <= tap_addr + L;
                    tap_count <= tap_count + L;
                    data_counter <= data_counter + 1;
                    buffer_rdptr <= buffer_rdptr - 1;
                else
                    interp_state <= OUTPUT_DATA;
                    -- Stop accumulation by after exiting this state
                end if;

            when OUTPUT_DATA => -- Wait until acc is ready
                if not accumulate_1 then
                    -- TODO fix dynamic offset
                    m_axis_mod_o.tdata <= std_logic_vector(accumulator(39 downto 39-16+1));
                    m_axis_mod_o.tvalid <= '1';
                end if;

                -- Wait for data to be accepted by downstream
                if m_axis_mod_i.tready and m_axis_mod_o.tvalid then
                    m_axis_mod_o.tvalid <= '0';
                    accumulator <= (others => '0');
                    interp_state <= SETUP_INTERPOLATE;
                end if;

            when others => -- IDLE
                interp_round		<= (others => '0');
                tap_addr			<= (others => '0');
                data_counter		<= (others => '0');
                accumulate_0		<= '0';

                -- When new data comes in, start to compute
                if s_axis_mod_i.tvalid and s_axis_mod_o.tready then
                    interp_state		<= SETUP_INTERPOLATE;
                end if;
        end case;
    end if;
  end process;

  s_axis_mod_o.tready <= '1' when interp_state = IDLE else '0';

end architecture;
