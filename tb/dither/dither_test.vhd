--dither test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dither_test is
	--
end dither_test;

architecture sim of dither_test is
	component dither_source is
		port(
		    clk_i	: in  std_logic;
			ena		: in std_logic;
			trig	: in std_logic := '0';
		    out_o	: out signed(15 downto 0)
		);
	end component;

	signal clk_i	: std_logic := '0';
	signal out_o	: signed(15 downto 0) := (others => '0');
	signal trig		: std_logic := '0';
begin
	dut: dither_source port map(
		clk_i => clk_i,
		ena => '1',
		trig => trig,
		out_o => out_o
	);

	process
	begin
	wait for 0.04 ms;
		trig <= not trig;
	end process;

	process
	begin
		wait for 0.005 ms;
		clk_i <= not clk_i;
	end process;
end sim;
