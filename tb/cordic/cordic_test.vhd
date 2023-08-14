--cordic test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use work.cordic.all;

entity cordic_test is
	--
end cordic_test;

architecture sim of cordic_test is

	signal clk_i, valid_o : std_logic := '0';
	signal phase_r : signed(23 downto 0) := (others => '0');
	signal phase_i : signed(15 downto 0) := (others => '0');
	signal sin_o, cos_o : signed(15 downto 0) := (others => '0');
	signal phase_valid_i : std_logic := '0';

	signal cos_ref_val, sin_ref_val : real := 0.0;
	signal cos_test_val, sin_test_val : real := 0.0;

	constant gain_scaling : real := 1.5;

begin
	dut: entity work.cordic_sincos generic map(
        SIZE => 24,
        ITERATIONS => 28,
		TRUNC_SIZE => 16,
        RESET_ACTIVE_LEVEL => '0'
	)
	port map(
		Clock => clk_i,
		Reset => '1',

		X => to_signed(integer(1.0/cordic_gain(24) * gain_scaling * 2.0 ** 22) , 24),
		Y => 24x"000000",
        Z => phase_r,
        Data_Valid => phase_valid_i,
		mode => cordic_rotate,

        X_result => cos_o,
        Y_result => sin_o,
        Result_valid => valid_o
	);

	phase_r <= phase_i & x"00";

	process
		variable cos_err, sin_err: real := 0.0;
		variable cos_max_err, sin_max_err: real := 0.0;
	begin
		wait until rising_edge(clk_i);
		phase_valid_i <= '1';
		wait until rising_edge(clk_i);
		phase_valid_i <= '0';
		wait until rising_edge(valid_o);

		wait until falling_edge(valid_o);
		cos_test_val <= real(to_integer(cos_o)) / real(2**14);
		sin_test_val <= real(to_integer(sin_o)) / real(2**14);

		cos_ref_val <= gain_scaling * cos(real(to_integer(phase_i)) / real(2**16) * MATH_2_PI);
		sin_ref_val <= gain_scaling * sin(real(to_integer(phase_i)) / real(2**16) * MATH_2_PI);
		wait for 0 ns;

		cos_err := abs(cos_ref_val - cos_test_val);
		sin_err := abs(sin_ref_val - sin_test_val);

		-- Max error
		if cos_err > cos_max_err then
			cos_max_err := cos_err;
		end if;
		if sin_err > sin_max_err then
			sin_max_err := sin_err;
		end if;

		report "phase=" & real'image(real(to_integer(phase_i)) / real(2.0 ** 16)) & lf &
			"cos_calc=" & real'image(cos_test_val) & " | sin_calc=" & real'image(sin_test_val) & lf &
			"cos_ref=" & real'image(cos_ref_val) & " | sin_ref=" & real'image(sin_ref_val) & lf &
			"cos_err=" & real'image(cos_err) & " | sin_err=" & real'image(sin_err) & lf &
			"cos_max_err=" & real'image(cos_max_err) & " | sin_max_err=" & real'image(sin_max_err) & lf;

		assert cos_err <= (1.0 / (2.0 ** 14)) report "Too large cos error" severity failure;
		assert sin_err <= (1.0 / (2.0 ** 14)) report "Too large sin error" severity failure;

		phase_i <= phase_i + 32;

		wait for 100 ns;
	end process;

	process
	begin
		wait for 5 ns;
		clk_i <= not clk_i;
	end process;
end sim;
