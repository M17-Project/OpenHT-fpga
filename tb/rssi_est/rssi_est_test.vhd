--rssi_est test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rssi_est_test is
	--
end rssi_est_test;

architecture sim of rssi_est_test is
	component rssi_est is
		port(
			clk_i	: in std_logic;
			r_i		: in signed(15 downto 0);
			r_o		: out unsigned(15 downto 0)
		);
	end component;

	signal clk_i : std_logic := '1';
	signal r_i : signed(15 downto 0) := (others => '0');
	signal r_o : unsigned(15 downto 0) := (others => '0');
begin
	dut: rssi_est port map(
		clk_i => clk_i,
		r_i => r_i,
		r_o => r_o
	);

	process
	begin
		wait for 1 ms;
		r_i <= x"0001";
		wait for 1 ms;
		r_i <= x"FFFF";
	end process;

	--process
	--begin
		--wait for 20.25 ms;
		--trig_i <= '1';
	--end process;

	process
	begin
		clk_i <= not clk_i;
		wait for 1 ms;
	end process;
end sim;
