--SPI receiver test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_receiver_test is
	--
end spi_receiver_test;

architecture sim of spi_receiver_test is
	component spi_receiver is
		port(
			mosi_i	: in std_logic;							-- serial data in
			sck_i	: in std_logic;							-- clock
			ncs_i	: in std_logic;							-- slave select signal
			data_o	: out std_logic_vector(31 downto 0);	-- data register
			nrst	: in std_logic;							-- reset
			ena		: in std_logic;							-- enable
			clk_i	: in std_logic							-- fast clock
		);
	end component;

	signal mosi_i	: std_logic := '0';
	signal sck_i	: std_logic := '0';
	signal ncs_i	: std_logic := '1';
	signal data_o	: std_logic_vector(31 downto 0) := (others => '0');
	signal nrst		: std_logic := '1';
	signal ena		: std_logic := '1';
	signal clk_i	: std_logic := '0';

	constant data : std_logic_vector(31 downto 0) := x"BEEFB00B";
begin
	dut: spi_receiver port map(mosi_i => mosi_i, sck_i => sck_i,
		ncs_i => ncs_i, data_o => data_o, nrst => nrst, ena => ena,
		clk_i => clk_i);

	process
	begin
		wait for 1.0005 ms;

		ncs_i <= '0';
		wait for 0.01 ms;
		sck_i <= '0';

		wait for 0.1 ms;

		for i in 0 to 31 loop
			mosi_i <= data(31-i);

			wait for 0.05 ms;
			sck_i <= '1';
			wait for 0.05 ms;
			sck_i <= '0';
			wait for 0.05 ms;
		end loop;

		sck_i <= '0';
		wait for 0.01 ms;
		mosi_i <= '0';
		wait for 0.1 ms;
		ncs_i <= '1';

		wait for 1 ms;

	end process;

	process
	begin
		clk_i <= not clk_i;
		wait for 0.001 ms;
	end process;
end sim;
