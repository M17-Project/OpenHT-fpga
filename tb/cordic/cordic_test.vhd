--cordic test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity cordic_test is
	--
end cordic_test;

architecture sim of cordic_test is

	signal clk_i, valid_o : std_logic := '0';
	signal phase_r : unsigned(23 downto 0) := (others => '0');
	signal phase_i : unsigned(15 downto 0) := (others => '0');
	signal sin_r, cos_r : signed(23 downto 0) := (others => '0');
	signal sin_o, cos_o : signed(15 downto 0) := (others => '0');
	signal phase_valid_i : std_logic := '0';

begin
	dut: entity work.cordic generic map(
        RES_WIDTH => 24,
        ITER_NUM => 20,
        COMP_COEFF => 24x"4DBA74" -- 16x"4DB9"
	)
	port map(
        clk_i => clk_i,
        phase_i => phase_r,
        phase_valid_i => phase_valid_i,
        sin_o => sin_r,
        cos_o => cos_r,
        valid_o => valid_o
	);
	sin_o <= sin_r(23 downto 23-16+1);
	cos_o <= cos_r(23 downto 23-16+1);
	phase_r <= phase_i & x"00";

	process
	begin
		wait until rising_edge(clk_i);
		phase_valid_i <= '1';
		wait until rising_edge(clk_i);
		phase_valid_i <= '0';
		wait until rising_edge(valid_o);

		assert abs(real(to_integer(sin_o)) - (sin(real(to_integer(phase_i))/real(16#8000#)*math_pi) * real(16#7FFF#))) < real(1.15) -- LSBs
		report "Fuckup!" & lf &
		"phase=" & integer'image(to_integer(phase_i)) & lf &
		"sin_calc=" & real'image(real(to_integer(sin_o))) & lf &
		"sin_true=" & real'image(sin(real(to_integer(phase_i))/real(16#8000#)*math_pi) * real(16#7FFF#))
		severity failure;
		phase_i <= phase_i + 1;

	end process;

	process
	begin
		wait for 5 ns;
		clk_i <= not clk_i;
	end process;
end sim;
