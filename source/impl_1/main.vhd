--main
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.regs_pkg.all;

entity main_all is
	port(
		-- 26 MHz clock input from the AT86
		clk_i 				: in std_logic;
		-- master reset, high active
		rst					: in std_logic;
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
		io0, io1, io2		: in std_logic;
		io3, io4, io5, io6	: out std_logic
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
	signal spi_rw					: std_logic := '0';										-- SPI R/W flag
	signal spi_rx_r, spi_tx_r		: std_logic_vector(15 downto 0) := (others => '0');
	signal spi_addr_r				: std_logic_vector(14 downto 0) := (others => '0');
	
	-- PLL block
	component pll_osc is
		port(
			rstn_i   : in std_logic;		-- reset in
			clki_i   : in std_logic;		-- reference input
			clkop_o  : out std_logic;		-- primary output
			clkos_o  : out std_logic;		-- secondary output 1
			clkos2_o : out std_logic		-- secondary output 1
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
			miso_o	: out std_logic;						-- serial data out
			mosi_i	: in std_logic;							-- serial data in
			sck_i	: in std_logic;							-- clock
			ncs_i	: in std_logic;							-- slave select signal
			data_o	: out std_logic_vector(15 downto 0);	-- received data register
			addr_o	: out std_logic_vector(14 downto 0);	-- address (for data read)
			data_i	: in std_logic_vector(15 downto 0);		-- input data register
			nrst	: in std_logic;							-- reset
			ena		: in std_logic;							-- enable
			rw		: inout std_logic;						-- read/write flag, r=0, w=1
			clk_i	: in std_logic							-- fast clock
		);
	end component;
begin
	------------------ port maps ------------------
	pll0: pll_osc port map(
		rstn_i => not rst,
		clki_i => clk_i,
		clkop_o => clk_152,
		clkos_o => clk_64,
		clkos2_o => clk_38
	);

	ddr_tx0: ddr_tx port map(
		clk_i => clk_64,
		data_i => data_r,
		rst_i => rst,
		clk_o => clk_tx_o,
		data_o => data_tx_o
	);
	
	ddr_rx0: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx09_i,
		rst_i => rst,
		sclk_o => clk_rx09,
		data_o => data_rx09_r
	);
	
	ddr_rx1: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx24_i,
		rst_i => rst,
		sclk_o => clk_rx24,
		data_o => data_rx24_r
	);
	
	spi0: spi_slave port map(		
		miso_o => spi_miso,
		mosi_i => spi_mosi,
		sck_i => spi_sck,
		ncs_i => spi_ncs,
		data_o => spi_rx_r,
		addr_o => spi_addr_r,
		data_i => spi_tx_r,
		nrst => not rst,
		ena => '1',
		rw => spi_rw,
		clk_i => clk_i
	);

	-- just some random combinatorial logic to keep the synthesizer happy
	data_r <= "01";
	io3 <= spi_rw;
	io4 <= clk_rx09 or clk_rx24 or data_rx09_r(0) or data_rx24_r(1); 
	io5 <= io1 and io0;
	io6 <= io2;
	
	--process()
		--
	--begin
		--
	--end process;
end magic;
