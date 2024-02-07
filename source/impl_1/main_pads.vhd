-------------------------------------------------------------
-- OpenHT's top-level unit
--
-- Wojciech Kaczmarski, SP5WWP
-- Morgan Diepart, ON4MOD
-- Alvaro, EA4HGZ
-- Sebastien Van Cauwenberghe, ON4SEB
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.regs_pkg.all;
use work.axi_stream_pkg.all;

entity main_pads is
	port(
		-- 32 MHz clock input from the AT86
		clk_i 				: in std_logic;
		-- master reset, high active
		nrst				: in std_logic;
		-- baseband TX (DDR)
		clk_tx_o			: out std_logic := '0';
		data_tx_o			: out std_logic := '0';
		-- baseband RX (DDR)
		clk_rx_i			: in std_logic;
		data_rx09_i			: in std_logic;
		data_rx24_i			: in std_logic;
		-- SPI slave exposed for the STM32
		spi_ncs				: in std_logic;
		spi_miso			: out std_logic := 'Z';
		spi_mosi			: in std_logic;
		spi_sck				: in std_logic;
		-- a bunch of IOs
		io0, io1, io2		: in std_logic;
		io3, io4, io5, io6	: out std_logic := '0'
	);
end main_pads;

architecture magic of main_pads is
	-------------------------------------- signals --------------------------------------
	-- 64 MHz clock
	signal clk_64 : std_logic := '0';
    signal lock_o : std_logic;

    signal data_tx_r : std_logic_vector(1 downto 0);
    signal data_rx09_r : std_logic_vector(1 downto 0);
    signal data_rx24_r : std_logic_vector(1 downto 0);
    signal clk_rx09_r : std_logic;
    signal clk_rx24_r : std_logic;
	----------------------------- low level building blocks -----------------------------
	-- main PLL block
	component pll_osc is
		port(
			rstn_i		: in std_logic;						-- reset in (low-active)
			clki_i		: in std_logic;						-- reference input
			clkop_o		: out std_logic;					-- primary output
			lock_o		: out std_logic						-- lock flag
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
begin

    ------------------------------------ MAIN --------------------------------------------
    main_all_inst : entity work.main_all
    port map (
      clk_i => clk_64,
      lock_i => lock_o, 
      nrst => nrst,
      data_tx_o => data_tx_r,
      clk_rx09_i => clk_rx09_r,
      data_rx09_i => data_rx09_r,
      clk_rx24_i => clk_rx09_r,
      data_rx24_i => data_rx24_r,
      spi_ncs => spi_ncs,
      spi_miso => spi_miso,
      spi_mosi => spi_mosi,
      spi_sck => spi_sck,
      io0 => io0,
      io1 => io1,
      io2 => io2,
      io3 => io3,
      io4 => io4,
      io5 => io5,
      io6 => io6
    );

	------------------------------------- PLL --------------------------------------------
	pll0: pll_osc port map(
		rstn_i => nrst,
		clki_i => clk_i,
		clkop_o => clk_64,
		lock_o => lock_o
	);

	---------------------------------------- RX -----------------------------------------
	-- sub-GHz receiver
	ddr_rx0: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx09_i,
		rst_i => '0', -- check if STATE=RX and the band is correct
		sclk_o => clk_rx09_r,
		data_o => data_rx09_r
	);

	-- 2.4 GHz receiver
	ddr_rx1: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx24_i,
		rst_i => '0', -- check if STATE=RX and the band is correct
		sclk_o => clk_rx24_r,
		data_o => data_rx24_r
	);

    ---------------------------------------- TX -----------------------------------------
	ddr_tx0: ddr_tx port map(
		clk_i => clk_64,
		data_i => data_tx_r,
		rst_i => '0',
		clk_o => clk_tx_o,
		data_o => data_tx_o
	);


end magic;
