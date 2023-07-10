--complex_mul test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity complex_mul_test is
	--
end complex_mul_test;

architecture sim of complex_mul_test is
	component complex_mul is
		port(
			a_re, a_im, b_re, b_im	: in signed(15 downto 0);
			c_re, c_im				: out signed(15 downto 0) := (others => '0')
		);
	end component;

	signal a, b, c, d, x, y : signed(15 downto 0) := (others => '0');
begin
	dut: complex_mul port map(
		a_re => a,
		a_im => b,
		b_re => c,
		b_im => d,
		c_re => x,
		c_im => y
	);

	process
	begin
		wait for 0.2 ms;
		a <= x"7FFF";
		b <= x"0000";
		c <= x"7FFF";
		d <= x"0000";
		wait for 0.2 ms;
		a <= x"7FFF";
		b <= x"7FFF";
		c <= x"7FFF";
		d <= x"7FFF";
		wait for 0.2 ms;
		a <= x"8000";
		b <= x"8000";
		c <= x"8000";
		d <= x"8000";
		wait for 0.2 ms;
		a <= x"8000";
		b <= x"0000";
		c <= x"7FFF";
		d <= x"0000";
		wait for 0.2 ms;
		a <= x"8000";
		b <= x"0000";
		c <= x"0000";
		d <= x"8000";
	end process;

	--process
	--begin
		--clk_i <= not clk_i;
		--wait for 0.1 ms;
	--end process;
end sim;
