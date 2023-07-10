--spi_slave test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave_test is
	--
end spi_slave_test;

architecture sim of spi_slave_test is
	component spi_slave is
        generic(
            MAX_ADDR : natural := 20
        );
		port(
			miso_o	: out std_logic;						-- serial data out
			mosi_i	: in std_logic;							-- serial data in
			sck_i	: in std_logic;							-- clock
			ncs_i	: in std_logic;							-- slave select signal
			data_o	: out std_logic_vector(15 downto 0);	-- received data register
			addr_o	: out std_logic_vector(13 downto 0);	-- address
			data_i	: in std_logic_vector(15 downto 0);		-- input data register
			nrst	: in std_logic;							-- reset
			ena		: in std_logic;							-- enable
			rw		: inout std_logic;						-- read/write flag 0: read, 1: write
			ld      : out std_logic;                        -- load signal for a FIFO (positive pulse after word end)
			clk_i	: in std_logic							-- fast clock
		);
	end component;

	signal clk_i : std_logic := '0';
	signal ena, miso, mosi, sck, rw, ld : std_logic := '0';
	signal ncs : std_logic := '1';
	signal data_o : std_logic_vector(15 downto 0) := (others => '0');
	signal data_i : std_logic_vector(15 downto 0) := (others => '0');
	signal addr : std_logic_vector(13 downto 0) := (others => '0');
	constant tx_data1 : std_logic_vector(31 downto 0) := x"8009" & x"0001";
	constant tx_data2 : std_logic_vector(15 downto 0) := x"0002";
	constant tx_data3 : std_logic_vector(15 downto 0) := x"0003";
begin
	dut: spi_slave port map(
		miso_o => miso,
		mosi_i => mosi,
		sck_i => sck,
		ncs_i => ncs,
		data_o => data_o,
		addr_o => addr,
		data_i => data_i,
		nrst => '1',
		ena => '1',
		rw => rw,
		ld => ld,
		clk_i => clk_i
	);

	process
	begin
		--wait for 4 ms;
		--wait for 2.125 ms;
		data_i <= x"1234";
		wait;
	end process;

	process
	begin
		wait for 0.5 ms;
		ncs <= '0';
		for i in 31 downto 0 loop
			mosi <= tx_data1(i);
			wait for 0.05 ms;
			sck <= '1';
			wait for 0.05 ms;
			sck <= '0';
		end loop;
		for i in 15 downto 0 loop
			mosi <= tx_data2(i);
			wait for 0.05 ms;
			sck <= '1';
			wait for 0.05 ms;
			sck <= '0';
		end loop;
		for i in 15 downto 0 loop
			mosi <= tx_data3(i);
			wait for 0.05 ms;
			sck <= '1';
			wait for 0.05 ms;
			sck <= '0';
		end loop;
		mosi <= '0';
		wait for 0.05 ms;
		mosi <= '0';
		ncs <= '1';
	end process;

	process
	begin
		wait for 0.005 ms;
		clk_i <= not clk_i;
	end process;
end sim;
