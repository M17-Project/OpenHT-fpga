--mag_est test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mag_est_test is
	--
end mag_est_test;

architecture sim of mag_est_test is
	component mag_est is
		port(
			clk_i		: in std_logic;
			trig_i		: in std_logic;
			i_i, q_i	: in signed(15 downto 0);
			est_o		: out unsigned(15 downto 0);
			rdy_o		: out std_logic := '0'
		);
	end component;

	signal clk_i, trig_i, rdy_o : std_logic := '0';
	signal i_i, q_i : signed(15 downto 0) := (others => '0');
	signal est_o : unsigned(15 downto 0) := (others => '0');
begin
	dut: mag_est port map(
		clk_i => clk_i,
		trig_i => trig_i,
		i_i => i_i,
		q_i => q_i,
		est_o => est_o,
		rdy_o => rdy_o
	);

	process
	begin
		wait for 0.5 ms;
		i_i <= x"d781";
		q_i <= x"f94f";
		wait for 0.5 ms;
		trig_i <= not trig_i;
	end process;

	process
	begin
		wait for 0.01 ms;
		clk_i <= not clk_i;
	end process;
end sim;
