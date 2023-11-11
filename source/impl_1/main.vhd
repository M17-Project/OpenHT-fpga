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
use work.apb_pkg.all;

entity main_all is
	generic(
		REV_MAJOR : natural;
		REV_MINOR : natural
	);
	port(
		-- 64 MHz clock input from the AT86
		clk_i 				: in std_logic;
		lock_i              : in std_logic;
		-- master reset, high active
		nrst				: in std_logic;
		-- baseband TX (DDR)
		data_tx_o			: out std_logic_vector(1 downto 0) := (others => '0');
		-- baseband RX (DDR)
		clk_rx09_i			: in std_logic;
		data_rx09_i			: in std_logic_vector(1 downto 0);
		clk_rx24_i			: in std_logic;
		data_rx24_i			: in std_logic_vector(1 downto 0);
		-- SPI slave exposed for the STM32
		spi_ncs				: in std_logic;
		spi_miso			: out std_logic := 'Z';
		spi_mosi			: in std_logic;
		spi_sck				: in std_logic;
		-- a bunch of IOs
		io0, io1, io2		: in std_logic;
		io3, io4, io5, io6	: out std_logic := '0'
	);
end main_all;

architecture magic of main_all is
	-------------------------------------- signals --------------------------------------

	signal tx_axis_iq_i					: axis_in_iq_t := axis_in_iq_null;
	signal tx_axis_iq_o 				: axis_out_iq_t;

	signal rx_axis_iq_09_o				: axis_in_iq_t := axis_in_iq_null;
	signal rx_axis_iq_09_i 				: axis_out_iq_t;
	signal rx_axis_iq_24_o				: axis_in_iq_t := axis_in_iq_null;
	signal rx_axis_iq_24_i 				: axis_out_iq_t;

	signal dout_o : std_logic_vector(15 downto 0);
	signal dout_vld_o : std_logic;
	signal cs_o : std_logic;
	signal din_i : std_logic_vector(15 downto 0);
	signal din_vld_i : std_logic;

	signal m_apb_in : apb_in_t;
	signal m_apb_out : apb_out_t;
begin
	---------------------------------------- Top -----------------------------------------
	top_common_inst : entity work.top_common
	generic map (
	  REV_MAJOR => REV_MAJOR,
	  REV_MINOR => REV_MINOR
	)
	port map (
	  clk_i => clk_i,
	  lock_i => lock_i,
	  nrst => nrst,
	  tx_axis_iq_i => tx_axis_iq_i,
	  tx_axis_iq_o => tx_axis_iq_o,
	  rx_axis_iq_09_i => rx_axis_iq_09_o,
	  rx_axis_iq_09_o => rx_axis_iq_09_i,
	  rx_axis_iq_24_i => rx_axis_iq_24_o,
	  rx_axis_iq_24_o => rx_axis_iq_24_i,
	  apb_in => m_apb_in,
	  apb_out => m_apb_out,
	  io0 => io0,
	  io1 => io1,
	  io2 => io2,
	  io3 => io3,
	  io4 => io4,
	  io5 => io5,
	  io6 => io6
	);
	---------------------------------------- RX -----------------------------------------
	ddr_pack_09_inst : entity work.ddr_pack
	port map (
	  clk_i => clk_i,
	  nrst_i => '1',
	  ddr_din => data_rx09_i,
	  ddr_clkin => clk_rx09_i,
	  m_axis_iq_o => rx_axis_iq_09_o,
	  m_axis_iq_i => rx_axis_iq_09_i
	);

	ddr_pack_24_inst : entity work.ddr_pack
	port map (
		clk_i => clk_i,
		nrst_i => '1',
		ddr_din => data_rx24_i,
		ddr_clkin => clk_rx24_i,
		m_axis_iq_o => rx_axis_iq_24_o,
		m_axis_iq_i => rx_axis_iq_24_i
	);

	---------------------------------------- TX -----------------------------------------

	ddr_unpack0: entity work.ddr_unpack port map(
		clk_i => clk_i,
		nrst_i => nrst,
		s_axis_iq_i => tx_axis_iq_i,
		s_axis_iq_o => tx_axis_iq_o,
		data_o => data_tx_o
	);

	----------------------------------- control etc. ------------------------------------
	spi_slave_inst : entity work.spi_slave
	port map (
	  clk_i => clk_i,
	  miso_o => spi_miso,
	  mosi_i => spi_mosi,
	  sck_i => spi_sck,
	  ncs_i => spi_ncs,
	  dout_o => dout_o,
	  dout_vld_o => dout_vld_o,
	  cs_o => cs_o,
	  din_i => din_i,
	  din_vld_i => din_vld_i
	);

	apb_bridge_inst : entity work.apb_bridge
	port map (
	  clk_i => clk_i,
	  rstn_i => nrst,
	  dout => dout_o,
	  dout_vld => dout_vld_o,
	  cs => cs_o,
	  din => din_i,
	  din_vld => din_vld_i,
	  m_apb_in => m_apb_in,
	  m_apb_out => m_apb_out
	);

end magic;
