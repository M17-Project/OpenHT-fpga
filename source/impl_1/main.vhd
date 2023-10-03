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

	-- DDR signals
	signal clk_rx09						: std_logic := '0';
	signal clk_rx24						: std_logic := '0';
	signal data_rx09_r					: std_logic_vector(1 downto 0) := (others => '0');
	signal data_rx24_r					: std_logic_vector(1 downto 0) := (others => '0');

	-- FIFOs
	signal fifo_in_ae, fifo_out_ae		: std_logic := '0';
	signal fifo_in_rd_data              : std_logic_vector(15 downto 0);
	signal fifo_in_rd_en                : std_logic;
	signal fifo_in_empty                : std_logic;
	signal fifo_in_full                 : std_logic;
	signal mod_fifo_ae					: std_logic := '0';
	signal tx_data                      : std_logic_vector(15 downto 0);
	signal tx_data_valid                : std_logic;
	signal fifo_in_wr                   : std_logic;

	-- misc
	signal source_axis_out_mod			: axis_in_mod_t;
	signal source_axis_in_mod			: axis_out_mod_t;
	signal tx_axis_iq_o					: axis_in_iq_t := axis_in_iq_null;
	signal tx_axis_iq_i 				: axis_out_iq_t;

	signal rx_axis_iq_09_o				: axis_in_iq_t := axis_in_iq_null;
	signal rx_axis_iq_09_i 				: axis_out_iq_t;
	signal rx_axis_iq_24_o				: axis_in_iq_t := axis_in_iq_null;
	signal rx_axis_iq_24_i 				: axis_out_iq_t;

	signal dout_o : std_logic_vector(15 downto 0);
	signal dout_vld_o : std_logic;
	signal cs_o : std_logic;
	signal din_i : std_logic_vector(15 downto 0);
	signal din_vld_i : std_logic;

	signal tx_apb_out : apb_out_t;
	signal common_apb_out : apb_out_t;
	signal m_apb_in : apb_in_t;
	signal m_apb_out : apb_out_t;
	signal m_apb_dec_in : apb_in_t;

	-- Global system state
	signal io3_sel : std_logic_vector(2 downto 0);
	signal io4_sel : std_logic_vector(2 downto 0);
	signal io5_sel : std_logic_vector(2 downto 0);
	signal io6_sel : std_logic_vector(2 downto 0);
	signal rxtx : std_logic_vector(1 downto 0);

begin

	---------------------------------------- RX -----------------------------------------
	ddr_pack_09_inst : entity work.ddr_pack
	port map (
	  clk_i => clk_i,
	  nrst_i => '1',
	  ddr_din => data_rx09_r,
	  ddr_clkin => clk_rx09,
	  m_axis_iq_o => rx_axis_iq_09_o,
	  m_axis_iq_i => rx_axis_iq_09_i
	);

	ddr_pack_24_inst : entity work.ddr_pack
	port map (
		clk_i => clk_i,
		nrst_i => '1',
		ddr_din => data_rx24_r,
		ddr_clkin => clk_rx24,
		m_axis_iq_o => rx_axis_iq_24_o,
		m_axis_iq_i => rx_axis_iq_24_i
	);

	-- IQ stream deserializer
	--des_inp <= data_rx09_r or data_rx24_r; -- crude, but works
	----des_inp <= data_rx09_r when regs_rw(CR_1)(1 downto 0)="00"
		----else data_rx24_r when regs_rw(CR_1)(1 downto 0)="01"
		----else (others => '0');
	--deserializer0: entity work.iq_des port map(
		--clk_i		=> clk_i,
		--ddr_clk_i	=> clk_rx09,
		--data_i		=> des_inp,
		--nrst		=> nrst,
		--i_o			=> i_r_pre,
		--q_o			=> q_r_pre,
		--drdy		=> drdy
	--);

	-- FIFO
	--iq_fifo_in: entity work.iq_fifo generic map(
		--DEPTH => 8,
		--D_WIDTH => 13
	--)
	--port map(
		--clk_i => clk_i,
		--nrst_i => nrst,
		--trig_i => drdy,
		--wr_clk_i => drdy,
		--rd_clk_i => drdy,
		--i_i => i_r_pre,
		--q_i => q_r_pre,
		--i_o => i_r,
		--q_o => q_r
	--);

	-- local oscillator, 40kHz
	--lo0: entity work.local_osc port map(
		--clk_i => clk_i,
		--trig_i => drdy,
		--i_o => lo_mix_i,
		--q_o => lo_mix_q
	--);

	-- mixer
	--mix0: entity work.complex_mul port map(
		--clk_i => clk_i,
		--a_re => signed(i_r(11 downto 0) & '0' & '0' & '0' & '0'), -- a gain of 2
		--a_im => signed(q_r(11 downto 0) & '0' & '0' & '0' & '0'), -- somehow concatenating with "0000" didn't work here
		--b_re => lo_mix_i,
		--b_im => lo_mix_q,
		--c_re => mix_i_o,
		--c_im => mix_q_o
	--);

	--channel_flt0: entity work.channel_filter
	--generic map(
		--SAMP_WIDTH => 16
	--)
	--port map(
		--clk_i		=> clk_i,
		--ch_width	=> regs_rw(CR_2)(10 downto 9),
		--i_i			=> mix_i_o,
		--q_i			=> mix_q_o,
		--i_o			=> flt_id_r,
		--q_o			=> flt_qd_r,
		--trig_i		=> drdy,
		--drdy_o		=> drdyd
	--);

	----mag_sq_r <= std_logic_vector(flt_id_r*flt_id_r + flt_qd_r*flt_qd_r);
	--rssi0: entity work.rssi_est port map(
		--clk_i => drdyd,
		--r_i => flt_id_r, --mag_sq_r(31 downto 16),
		--std_logic_vector(r_o) => rssi_r,
		--rdy => rssi_rdy
	--);

	--rssi_fir0: entity work.fir_rssi port map(
		--clk_i => clk_38,
		--data_i => signed('0' & rssi_r(14 downto 0)),
		--std_logic_vector(data_o) => regs_r(RSSI_REG),
		--trig_i => rssi_rdy
		----drdy_o =>
	--);

	--am_demod0: entity work.mag_est port map(
		--clk_i => clk_38,
		--trig_i => drdyd,
		--i_i => flt_id_r,
		--q_i => flt_qd_r,
		--est_o => am_demod_raw,
		--rdy_o => am_demod_rdy
	--);

	--fm_demod0: entity work.freq_demod port map(
		--clk_i => drdyd,
		--i_i => flt_id_r(14 downto 0) & '0',
		--q_i => flt_qd_r(14 downto 0) & '0',
		--demod_o => fm_demod_raw
	--);

	-- demod out FIFO
	--demod_out_fifo: entity work.fifo_dc generic map(
		--DEPTH => 32,
		--D_WIDTH => 16
	--)
	--port map(
		--wr_clk_i => drdyd,
        --rd_clk_i => regs_latch and demod_reg_check, -- read samples only when address is DEMOD_REG
        --data_i => demod_raw,
        --data_o => demod_out_pre,
        --fifo_ae => fifo_out_ae,
		--fifo_full => open,
		--fifo_empty => open
	--);

	---------------------------------------- TX -----------------------------------------
	fifo_in_wr <= tx_data_valid and not fifo_in_full;

	mod_in_fifo: entity work.fifo_simple
	generic map(
		g_DEPTH => 32,
		g_WIDTH => 16
    )
	port map(
		i_rstn_async => nrst,
		i_clk => clk_i,
		-- FIFO Write Interface
		i_wr_en => fifo_in_wr,
		i_wr_data => tx_data, -- endianness fix
		o_full => fifo_in_full,
		-- FIFO Read Interface
		i_rd_en => fifo_in_rd_en,
		o_rd_data => fifo_in_rd_data,
		o_ae => fifo_in_ae,
		o_empty => fifo_in_empty
	);

	axis_mod_fifo_if_inst : entity work.axis_mod_fifo_if
	generic map (
	  G_DATA_SIZE => 16
	)
	port map (
	  clk => clk_i,
	  nrst => nrst,
	  fifo_rd_en => fifo_in_rd_en,
	  fifo_rd_data => fifo_in_rd_data,
	  fifo_ae => fifo_in_ae,
	  fifo_empty => fifo_in_empty,
	  m_axis_mod_o => source_axis_out_mod,
	  m_axis_mod_i => source_axis_in_mod
	);

	tx_chain_inst : entity work.tx_chain
	port map (
	  clk_64 => clk_i,
	  resetn => nrst,
	  s_apb_in => m_apb_dec_in,
	  s_apb_out => tx_apb_out,
	  source_axis_out_mod => source_axis_out_mod,
	  source_axis_in_mod => source_axis_in_mod,
	  tx_axis_iq_o => tx_axis_iq_o,
	  tx_axis_iq_i => tx_axis_iq_i
	);

	ddr_unpack0: entity work.ddr_unpack port map(
		clk_i => clk_i,
		nrst_i => nrst,
		s_axis_iq_i => tx_axis_iq_o,
		s_axis_iq_o => tx_axis_iq_i,
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

	common_apb_regs_inst : entity work.common_apb_regs
	generic map (
	  PSEL_ID => 0,
	  REV_MAJOR => REV_MAJOR,
	  REV_MINOR => REV_MINOR
	)
	port map (
	  clk => clk_i,
	  s_apb_in => m_apb_dec_in,
	  s_apb_out => common_apb_out,
	  pll_lock => lock_i,
	  io3_sel => io3_sel,
	  io4_sel => io4_sel,
	  io5_sel => io5_sel,
	  io6_sel => io6_sel,
	  tx_data => tx_data,
	  tx_data_valid => tx_data_valid,
	  rxtx => rxtx
	);

	apb_merge_inst : entity work.apb_merge
	generic map (
	  N_SLAVES => 2
	)
	port map (
	  clk_i => clk_i,
	  rstn_i => nrst,
	  m_apb_in => m_apb_in,
	  m_apb_out => m_apb_out,
	  s_apb_in => m_apb_dec_in,
	  s_apb_out(0) => common_apb_out,
	  s_apb_out(1) => tx_apb_out
	);

	-- I/Os
	-- automatically select the source of the fifo_ae signal
	mod_fifo_ae <= fifo_in_ae when rxtx = "01"
		else fifo_out_ae when rxtx ="10"
		else '0';

	-- IO update
	with io3_sel select
	io3 <= lock_i        	when "000",	-- PLL lock flag
	'0'					when "001",
	'0'					when "010",
	'0'					when "011",
	'0'					when "100",
	mod_fifo_ae			when "101",	-- baseband FIFO almost empty flag
	'0'					when others;

	io4 <= '0'; --mux_axis_out_iq.tready;
	io5 <= '0'; --freq_mod_axis_in_iq.tvalid;
	io6 <= '0'; --mux_axis_in_iq.tvalid;
end magic;
