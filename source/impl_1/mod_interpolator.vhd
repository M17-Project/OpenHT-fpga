-------------------------------------------------------------
-- Mod interpolator
-- FIR taps must be symmetric
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

entity mod_interpolator is
  generic
  (
    N_TAPS : natural; --!!! TAPS count must be a multiple of L
    L      : natural -- Interpolation factor
  );
  port
  (
    clk_i        : in std_logic;
    s_axis_mod_i : in axis_in_mod_t;
    s_axis_mod_o : out axis_out_mod_t;
    m_axis_mod_o : out axis_in_mod_t;
    m_axis_mod_i : in axis_out_mod_t
  );
end entity mod_interpolator;

architecture rtl of mod_interpolator is
    type interp_state_t is (IDLE, FIR_COMPUTE, OUTPUT_DATA);
    signal interp_state : interp_state_t := IDLE;
    signal interp_round : unsigned(3 downto 0);
    signal tap_addr    : unsigned(7 downto 0);
    signal data_counter : unsigned(7 downto 0);

    signal accumulator : signed(39 downto 0) := (others => '0');
    signal accumulate_0 : std_logic;
    signal accumulate_1 : std_logic;

    signal coeff_data : signed(15 downto 0) := X"0001";
    signal buffer_data : signed(15 downto 0) := X"0002";

begin

    assert(N_TAPS mod L = 0, "Taps count must be a multiple of L");

    process (clk_i)
    begin
        if rising_edge(clk_i) then
        s_axis_mod_o.tready <= '0';
        accumulate_1 <= accumulate_0;

        if accumulate_1 then
            accumulator <= accumulator + (X"00" & coeff_data * buffer_data);
        end if;

        case interp_state is
            when FIR_COMPUTE =>
                accumulate_0 <= '1'; -- Accumulate

                -- Compute N samples FIR
                if data_counter < (N_TAPS/L) - 1 then
                    tap_addr <= tap_addr + L;
                    data_counter <= data_counter + 1;
                else
                    interp_state        <= OUTPUT_DATA;
                    interp_round        <= interp_round + 1;
                    accumulate_0 <= '0'; -- Stop accumulation
                end if;

            when OUTPUT_DATA => -- Wait until acc is ready
                data_counter <= (others => '0');
                if not accumulate_1 then
                    m_axis_mod_o.tvalid <= '1';
                end if;

                -- Wait for data to be accepted by downstream
                if m_axis_mod_i.tready and m_axis_mod_o.tvalid then
                    m_axis_mod_o.tvalid <= '0';
                    accumulator <= (others => '0');
                    if interp_round < L then
                        interp_state                 <= FIR_COMPUTE;
                        tap_addr                     <= (others => '0');
                        tap_addr(interp_round'range) <= interp_round;
                    else
                        interp_state <= IDLE;
                    end if;
                end if;

            when others => -- IDLE
                s_axis_mod_o.tready <= '1';
                interp_round        <= (others => '0');
                tap_addr           <= (others => '0');
                data_counter <= (others => '0');
                accumulate_0 <= '0';

                -- When new data comes in, start to compute
                if s_axis_mod_i.tvalid and s_axis_mod_o.tready then
                    interp_state <= FIR_COMPUTE;
                    s_axis_mod_o.tready <= '0';
                end if;
        end case;
    end if;
  end process;

end architecture;
