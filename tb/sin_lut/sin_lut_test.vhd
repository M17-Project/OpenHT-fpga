--sin_lut test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sin_lut_test is
	--
end sin_lut_test;

architecture sim of sin_lut_test is
	component sincos_lut is
		port(
		    theta_i		:   in  std_logic_vector(9 downto 0);
		    sine_o		:   out std_logic_vector(11 downto 0);
			cosine_o	:   out std_logic_vector(11 downto 0)
		);
	end component;

	signal phase	: std_logic_vector(9 downto 0) := (others => '0');
	signal sine_o	: std_logic_vector(11 downto 0) := (others => '0');
	signal cosine_o	: std_logic_vector(11 downto 0) := (others => '0');
begin
	dut: sincos_lut port map(theta_i => phase, sine_o => sine_o, cosine_o => cosine_o);

	process
	begin
		wait for 0.01 ms;
		phase <= std_logic_vector(unsigned(phase)+1);
		wait for 0.01 ms;
	end process;
end sim;
