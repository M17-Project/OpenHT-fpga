--main
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity main_all is
	port(
		-- 26 MHz clock input from the AT86
		clk_i 				: in std_logic;
		-- master reset, low active
		nrst				: in std_logic;
		-- baseband TX (DDR)
		clk_tx_o			: out std_logic;
		data_tx_o			: out std_logic;
		-- baseband RX (DDR)
		clk_rx_i			: in std_logic;
		data_rx09_i			: in std_logic;
		data_rx24_i			: in std_logic;
		-- SPI slave exposed for the STM32
		spi_ncs				: in std_logic;
		spi_miso			: out std_logic;
		spi_mosi			: in std_logic;
		spi_sck				: in std_logic;
		-- a bunch of IOs
		io0, io1, io2, io3	: in std_logic;
		io4, io5, io6, io7	: out std_logic
	);
end main_all;

architecture magic of main_all is
	-- 38, 64 and 152 MHz clocks
	signal clk_38, clk_64, clk_152	: std_logic;
	
	-- "constant" source
	signal data_r					: std_logic_vector(1 downto 0) := (others => '0');
	-- dummy
	signal clk_rx09					: std_logic;
	signal clk_rx24					: std_logic;
	signal data_rx09_r				: std_logic_vector(1 downto 0);
	signal data_rx24_r				: std_logic_vector(1 downto 0);
	-- SPI data regs
	signal spi_rx_r					: std_logic_vector(31 downto 0);
	
	-- PLL block
	component pll_osc is
		port(
			clki_i  : in std_logic;		-- reference input
			clkop_o : out std_logic;	-- primary output
			clkos_o : out std_logic		-- secondary output
		);
	end component;
	
	-- DDR interfaces
	component ddr_tx is
		port(
			clk_i  : in std_logic;
			data_i : in std_logic_vector(1 downto 0);
			rst_i  : in std_logic;
			clk_o  : out std_logic;
			data_o : out std_logic
		);
	end component;
	
	component ddr_rx is
		port(
			clk_i  : in std_logic;
			data_i : in std_logic;
			rst_i  : in std_logic;
			sclk_o : out std_logic;
			data_o : out std_logic_vector(1 downto 0)
		);
	end component;
	
	-- SPI slave interface
	component spi_slave is
		port(
			mosi_i	: in std_logic;
			sck_i	: in std_logic;
			ncs_i	: in std_logic;
			data_o	: out std_logic_vector(31 downto 0);
			nrst	: in std_logic;
			ena		: in std_logic;
			clk_i	: in std_logic
		);
	end component;
begin
	------------------ port maps ------------------
	pll0: pll_osc port map(
		clki_i => clk_i,
		clkop_o => clk_64,
		clkos_o => clk_152
	);

	ddr_tx0: ddr_tx port map(
		clk_i => clk_64,
		data_i => data_r,
		rst_i => '0',
		clk_o => clk_tx_o,
		data_o => data_tx_o
	);
	
	ddr_rx0: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx09_i,
		rst_i => '0',
		sclk_o => clk_rx09,
		data_o => data_rx09_r
	);
	
	ddr_rx1: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx24_i,
		rst_i => '0',
		sclk_o => clk_rx24,
		data_o => data_rx24_r
	);
	
	spi0: spi_slave port map(
		mosi_i => spi_mosi,
		sck_i => spi_sck,
		ncs_i => spi_ncs,
		data_o => spi_rx_r,
		nrst => nrst,
		ena => '1',
		clk_i => clk_i
	);

	io4 <= clk_rx09 or clk_rx24 or data_rx09_r(0) or data_rx24_r(1); -- just some random combinatorial logic to keep the synthesizer happy

	spi_miso <= io0;
	io5 <= io1;
	io6 <= io2;
	io7 <= io3;
	
	--process()
		--
	--begin
		--
	--end process;
end magic;
