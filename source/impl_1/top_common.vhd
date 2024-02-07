-------------------------------------------------------------
-- OpenHT's top-level unit with internal busses
--
-- Sebastien Van Cauwenberghe, ON4SEB
-- M17 Project
-- November 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.regs_pkg.all;
use work.axi_stream_pkg.all;
use work.apb_pkg.all;

entity top_common is
	port(
		-- 64 MHz clock input from the AT86
		clk_i 				: in std_logic;
		lock_i              : in std_logic;
		-- master reset, high active
		nrst				: in std_logic;
		-- baseband TX (DDR)
		tx_axis_iq_i	: out axis_in_iq_t := axis_in_iq_null;
		tx_axis_iq_o	: in axis_out_iq_t;
		-- baseband RX (DDR)
		rx_axis_iq_09_i		: in axis_in_iq_t := axis_in_iq_null;
		rx_axis_iq_09_o 	: out axis_out_iq_t;
		rx_axis_iq_24_i		: in axis_in_iq_t := axis_in_iq_null;
		rx_axis_iq_24_o  	: out axis_out_iq_t;
		-- APB
		apb_in : in apb_in_t;
		apb_out : out apb_out_t;
		-- a bunch of IOs
		io0, io1, io2		: in std_logic;
		io3, io4, io5, io6	: out std_logic := '0';
		-- TX Debug
		tx_dbg0_in : out axis_in_iq_t;
		tx_dbg0_out : out axis_out_iq_t;
		tx_dbg1_in : out axis_in_iq_t;
		tx_dbg1_out : out axis_out_iq_t;
		tx_dbg2_in : out axis_in_iq_t;
		tx_dbg2_out : out axis_out_iq_t;
		tx_dbg3_in : out axis_in_iq_t;
		tx_dbg3_out : out axis_out_iq_t;
		tx_dbg4_in : out axis_in_iq_t;
		tx_dbg4_out : out axis_out_iq_t;
		tx_dbg5_in : out axis_in_iq_t;
		tx_dbg5_out : out axis_out_iq_t;
		tx_dbg6_in : out axis_in_iq_t;
		tx_dbg6_out : out axis_out_iq_t;
		tx_dbg7_in : out axis_in_iq_t;
		tx_dbg7_out : out axis_out_iq_t;
		-- RX debug
		rx_dbg0_in : out axis_in_iq_t;
		rx_dbg0_out : out axis_out_iq_t;
		rx_dbg1_in : out axis_in_iq_t;
		rx_dbg1_out : out axis_out_iq_t;
		rx_dbg2_in : out axis_in_iq_t;
		rx_dbg2_out : out axis_out_iq_t;
		rx_dbg3_in : out axis_in_iq_t;
		rx_dbg3_out : out axis_out_iq_t;
		rx_dbg4_in : out axis_in_iq_t;
		rx_dbg4_out : out axis_out_iq_t;
		rx_dbg5_in : out axis_in_iq_t;
		rx_dbg5_out : out axis_out_iq_t
	);
end top_common;

architecture magic of top_common is
	-------------------------------------- signals --------------------------------------

	-- TX chain
	signal tx_fifo_ae					: std_logic := '0';
	signal tx_fifo_af					: std_logic := '0';
	signal tx_fifo_rd_data              : std_logic_vector(15 downto 0);
	signal tx_fifo_rd_en                : std_logic;
	signal tx_fifo_empty                : std_logic;
	signal tx_fifo_full                 : std_logic;
	signal tx_fifo_wr_data              : std_logic_vector(15 downto 0);
	signal tx_fifo_wr_data_valid        : std_logic;
	signal tx_fifo_wr                   : std_logic;
	signal tx_fifo_count                : std_logic_vector(7 downto 0);

	signal tx_source_axis_o  			: axis_in_iq_t;
	signal tx_source_axis_i     		: axis_out_iq_t;

	-- RX chain
	signal rx_fifo_ae					: std_logic := '0';
	signal rx_fifo_af					: std_logic := '0';
	signal rx_fifo_rd_data              : std_logic_vector(15 downto 0);
	signal rx_fifo_rd_en                : std_logic;
	signal rx_fifo_empty                : std_logic;
	signal rx_fifo_full                 : std_logic;
	signal rx_fifo_wr_data              : std_logic_vector(15 downto 0);
	signal rx_fifo_wr                   : std_logic;
	signal rx_fifo_count                : std_logic_vector(7 downto 0);

	signal rx_demod_out  				: axis_in_iq_t;
	signal rx_demod_in 		     		: axis_out_iq_t;

	signal mod_fifo_ae					: std_logic := '0';
	signal sql_active                   : std_logic;

	-- APB slaves
	signal tx_apb_out : apb_out_t;
	signal rx_apb_out : apb_out_t;
	signal common_apb_out : apb_out_t;
	signal m_apb_dec_in : apb_in_t;

	-- Global system state
	signal io3_sel : std_logic_vector(2 downto 0);
	signal io4_sel : std_logic_vector(2 downto 0);
	signal io5_sel : std_logic_vector(2 downto 0);
	signal io6_sel : std_logic_vector(2 downto 0);
	signal rxtx : std_logic_vector(1 downto 0);
	signal band_sel : std_logic;

begin

	---------------------------------------- RX -----------------------------------------
	rx_chain_inst : entity work.rx_chain
	port map (
	  clk_64 => clk_i,
	  resetn => nrst,
	  s_apb_in => m_apb_dec_in,
	  s_apb_out => rx_apb_out,
	  band_i => band_sel,
	  rx_mod09_iq_i => rx_axis_iq_09_i,
	  rx_mod09_iq_o => rx_axis_iq_09_o,
	  rx_mod24_iq_i => rx_axis_iq_24_i,
	  rx_mod24_iq_o => rx_axis_iq_24_o,
	  rx_demod_iq_out => rx_demod_out,
	  rx_demod_iq_in => rx_demod_in,
	  sql_active => sql_active,
	  dbg0_in => rx_dbg0_in,
	  dbg0_out => rx_dbg0_out,
	  dbg1_in => rx_dbg1_in,
	  dbg1_out => rx_dbg1_out,
	  dbg2_in => rx_dbg2_in,
	  dbg2_out => rx_dbg2_out,
	  dbg3_in => rx_dbg3_in,
	  dbg3_out => rx_dbg3_out,
	  dbg4_in => rx_dbg4_in,
	  dbg4_out => rx_dbg4_out,
	  dbg5_in => rx_dbg5_in,
	  dbg5_out => rx_dbg5_out
	);

	axis_rx_fifo_if_inst : entity work.axis_rx_fifo_if
	generic map (
		G_DATA_SIZE => 16
	)
	port map (
		clk => clk_i,
		nrst => nrst,
		s_axis_i => rx_demod_out,
		s_axis_o => rx_demod_in,
		fifo_wr_en => rx_fifo_wr,
		fifo_wr_data => rx_fifo_wr_data,
		fifo_full => rx_fifo_full
	);

	rx_fifo_inst: entity work.fifo_simple
	generic map(
		g_DEPTH => 64,
		g_WIDTH => 16,
		g_AE_THRESH => 16,
		g_AF_THRESH => 48
    )
	port map(
		i_rstn_async => nrst,
		i_clk => clk_i,
		-- FIFO Write Interface
		i_wr_en => rx_fifo_wr,
		i_wr_data => rx_fifo_wr_data,
		o_full => rx_fifo_full,
		-- FIFO Read Interface
		i_rd_en => rx_fifo_rd_en,
		o_rd_data => rx_fifo_rd_data,
		o_ae => rx_fifo_ae,
		o_af => rx_fifo_af,
		o_empty => rx_fifo_empty,
		o_count => rx_fifo_count
	);

	---------------------------------------- TX -----------------------------------------
	tx_fifo_wr <= tx_fifo_wr_data_valid and not tx_fifo_full;

	tx_fifo_inst: entity work.fifo_simple
	generic map(
		g_DEPTH => 32,
		g_WIDTH => 16,
		g_AE_THRESH => 12,
		g_AF_THRESH => 24
    )
	port map(
		i_rstn_async => nrst,
		i_clk => clk_i,
		-- FIFO Write Interface
		i_wr_en => tx_fifo_wr,
		i_wr_data => tx_fifo_wr_data,
		o_full => tx_fifo_full,
		-- FIFO Read Interface
		i_rd_en => tx_fifo_rd_en,
		o_rd_data => tx_fifo_rd_data,
		o_ae => tx_fifo_ae,
		o_af => tx_fifo_af,
		o_empty => tx_fifo_empty,
		o_count => tx_fifo_count
	);

	axis_mod_fifo_if_inst : entity work.axis_mod_fifo_if
	generic map (
	  G_DATA_SIZE => 16
	)
	port map (
	  clk => clk_i,
	  nrst => nrst,
	  fifo_rd_en => tx_fifo_rd_en,
	  fifo_rd_data => tx_fifo_rd_data,
	  fifo_ae => tx_fifo_ae,
	  fifo_empty => tx_fifo_empty,
	  m_axis_mod_o => tx_source_axis_o,
	  m_axis_mod_i => tx_source_axis_i
	);

	tx_chain_inst : entity work.tx_chain
	port map (
	  clk_64 => clk_i,
	  resetn => nrst,
	  s_apb_in => m_apb_dec_in,
	  s_apb_out => tx_apb_out,
	  source_axis_out => tx_source_axis_o,
	  source_axis_in => tx_source_axis_i,
	  tx_axis_iq_o => tx_axis_iq_i,
	  tx_axis_iq_i => tx_axis_iq_o,
	  dbg0_in => tx_dbg0_in,
	  dbg0_out => tx_dbg0_out,
	  dbg1_in => tx_dbg1_in,
	  dbg1_out => tx_dbg1_out,
	  dbg2_in => tx_dbg2_in,
	  dbg2_out => tx_dbg2_out,
	  dbg3_in => tx_dbg3_in,
	  dbg3_out => tx_dbg3_out,
	  dbg4_in => tx_dbg4_in,
	  dbg4_out => tx_dbg4_out,
	  dbg5_in => tx_dbg5_in,
	  dbg5_out => tx_dbg5_out,
	  dbg6_in => tx_dbg6_in,
	  dbg6_out => tx_dbg6_out,
	  dbg7_in => tx_dbg7_in,
	  dbg7_out => tx_dbg7_out
	);

	----------------------------------- control etc. ------------------------------------

	common_apb_regs_inst : entity work.common_apb_regs
	generic map (
	  PSEL_ID => C_COM_REGS_PSEL
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
	  tx_data => tx_fifo_wr_data,
	  tx_data_valid => tx_fifo_wr_data_valid,
	  tx_data_count => tx_fifo_count,
	  tx_fifo_flags => tx_fifo_empty & tx_fifo_full & tx_fifo_ae & tx_fifo_af,
	  rx_data => rx_fifo_rd_data,
	  rx_data_valid => rx_fifo_rd_en,
	  rx_data_count => rx_fifo_count,
	  rx_fifo_flags => rx_fifo_empty & rx_fifo_full & rx_fifo_ae & rx_fifo_af,
	  rxtx => rxtx,
	  band_sel => band_sel
	);

	apb_merge_inst : entity work.apb_merge
	generic map (
	  N_SLAVES => 3
	)
	port map (
	  clk_i => clk_i,
	  rstn_i => nrst,
	  m_apb_in => apb_in,
	  m_apb_out => apb_out,
	  s_apb_in => m_apb_dec_in,
	  s_apb_out(0) => common_apb_out,
	  s_apb_out(1) => tx_apb_out,
	  s_apb_out(2) => rx_apb_out
	);

	-- I/Os
	-- automatically select the source of the fifo_ae signal
	mod_fifo_ae <= tx_fifo_ae when rxtx = "01"
		else rx_fifo_af when rxtx ="10"
		else '0';

	-- IO update
	with io3_sel select
	io3 <= lock_i       when "000",	-- PLL lock flag
	'0'					when "001",
	'0'					when "010",
	'0'					when "011",
	'0'					when "100",
	mod_fifo_ae			when "101",	-- baseband FIFO almost empty flag
	'0'					when others;

	with io4_sel select
	io4 <= '0'        when "000",
	       sql_active when "001",
		   '0'        when others;

	io5 <= '0'; --freq_mod_axis_in_iq.tvalid;
	io6 <= '0'; --mux_axis_in_iq.tvalid;
end magic;
