--dither_adder test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dither_adder_test is
	--
end dither_adder_test;

architecture sim of dither_adder_test is
	component dither_adder is
		port(
			phase_i	: in unsigned(20 downto 0);
			dith_i	: in signed(7 downto 0);
        	phase_o	: out unsigned(20 downto 0)
		);
	end component;

	signal phase_i	: unsigned(20 downto 0) := '1'& x"FFF00";
	signal dith_i	: signed(7 downto 0) := x"80";
    signal phase_o	: unsigned(20 downto 0) := (others => '0');
begin
	dut: dither_adder port map(
        phase_i	=> phase_i,
		dith_i => dith_i,
        phase_o	=> phase_o
	);

	process
	begin
		wait for 0.01 ms;
		phase_i <= phase_i+1;
	end process;
end sim;
