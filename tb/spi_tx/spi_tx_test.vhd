--spi_tx test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_tx_test is
	--
end spi_tx_test;

architecture sim of spi_tx_test is
	component spi_tx is
		port(
			clk_i		: in std_logic;							-- clock in
			trig_i		: in std_logic;							-- data transfer trig in
			data_i		: in std_logic_vector(15 downto 0);		-- parallel data in
			ncs_o		: inout std_logic := '1';				-- chip select out
			data_o		: out std_logic := '0';					-- data out
			sck_o		: inout std_logic := '0'				-- data clock
		);
	end component;

	signal clk_i : std_logic := '0';
	signal trig_i : std_logic := '0';
	signal data_i : std_logic_vector(15 downto 0) := x"8001";
	signal ncs_o : std_logic := '1';
	signal data_o : std_logic := '0';
	signal sck_o : std_logic := '0';
begin
	dut: spi_tx port map(
		clk_i => clk_i,
		trig_i => trig_i,
		data_i => data_i,
		ncs_o => ncs_o,
		data_o => data_o,
		sck_o => sck_o
	);

	process
	begin
		wait for 1 ms;
		trig_i <= '1';
		wait for 0.1 ms;
		trig_i <= '0';
	end process;

	process
	begin
		clk_i <= not clk_i;
		wait for 10 us;
	end process;
end sim;
