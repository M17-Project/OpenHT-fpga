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

entity main_all is
	generic(
		REV_MAJOR			: natural := 0;
		REV_MINOR			: natural := 2
	);
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
end main_all;

architecture magic of main_all is
	-------------------------------------- signals --------------------------------------
	-- 64 MHz clock
	signal clk_64 : std_logic := '0';

	-- DDR signals
	signal clk_rx09						: std_logic := '0';
	signal clk_rx24						: std_logic := '0';
	signal data_rx09_r					: std_logic_vector(1 downto 0) := (others => '0');
	signal data_rx24_r					: std_logic_vector(1 downto 0) := (others => '0');
	signal data_tx_r					: std_logic_vector(1 downto 0) := (others => '0');
	-- SPI data regs
	signal spi_rw						: std_logic := '0';										-- SPI R/W flag
	signal spi_rx_r, spi_tx_r			: std_logic_vector(15 downto 0) := (others => '0');		-- SPI receive/send data
	signal spi_addr_r					: std_logic_vector(13 downto 0) := (others => '0');		-- SPI received address
	-- IQ - TX
	signal i_out, q_out					: std_logic_vector(15 downto 0) := (others => '0');
	-- control registers related
	signal reg_data_wr, reg_data_rd		: std_logic_vector(15 downto 0) := (others => '0');		-- data to be written to/read from a specific register
	signal reg_rw						: std_logic := '0';
	signal regs_rw						: rw_regs_t := (others => (others => '0'));
	signal regs_r						: r_regs_t := (others => (others => '0'));
	signal regs_latch					: std_logic := '0';										-- data latch signal for the control regs array
	-- FIFOs
	signal fifo_in_ae, fifo_out_ae		: std_logic := '0';
	signal fifo_in_rd_data              : std_logic_vector(15 downto 0);
	signal fifo_in_rd_en                : std_logic;
	signal fifo_in_empty                : std_logic;
	signal mod_fifo_ae					: std_logic := '0';
	signal fifo_in_reg_check			: std_logic := '0';
	-- misc
	signal source_axis_out_mod			: axis_in_mod_t;
	signal source_axis_in_mod			: axis_out_mod_t;
	signal resampler_axis_out_mod		: axis_in_mod_t;
	signal resampler_axis_in_mod		: axis_out_mod_t;
	signal ctcss_axis_out_mod			: axis_in_mod_t;
	signal ctcss_axis_in_mod			: axis_out_mod_t;
	signal freq_mod_axis_in_iq			: axis_in_iq_t := axis_in_iq_null;
	signal mux_axis_in_iq				: axis_in_iq_t := axis_in_iq_null;
	signal mux_axis_out_iq				: axis_out_iq_t;
	signal unpack_axis_out_iq			: axis_out_iq_t;
	signal samp_clk						: std_logic := '0';

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
	------------------------------------- port maps -------------------------------------
	pll0: pll_osc port map(
		rstn_i => nrst,
		clki_i => clk_i,
		clkop_o => clk_64,
		lock_o => regs_r(SR_2)(0)
	);

	---------------------------------------- RX -----------------------------------------
	-- sub-GHz receiver
	--ddr_rx0: ddr_rx port map(
		--clk_i => clk_rx_i,
		--data_i => data_rx09_i,
		--rst_i => (regs_rw(CR_2)(0) and not regs_rw(CR_2)(1)) or (regs_rw(CR_1)(0)), -- check if STATE=RX and the band is correct
		--sclk_o => clk_rx09,
		--data_o => data_rx09_r
	--);

	-- 2.4 GHz receiver
	--ddr_rx1: ddr_rx port map(
		--clk_i => clk_rx_i,
		--data_i => data_rx24_i,
		--rst_i =>  (regs_rw(CR_2)(0) and not regs_rw(CR_2)(1)) or (not regs_rw(CR_1)(0)), -- check if STATE=RX and the band is correct
		--sclk_o => clk_rx24,
		--data_o => data_rx24_r
	--);

	-- IQ stream deserializer
	--des_inp <= data_rx09_r or data_rx24_r; -- crude, but works
	----des_inp <= data_rx09_r when regs_rw(CR_1)(1 downto 0)="00"
		----else data_rx24_r when regs_rw(CR_1)(1 downto 0)="01"
		----else (others => '0');
	--deserializer0: entity work.iq_des port map(
		--clk_i		=> clk_64,
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
		--clk_i => clk_64,
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
		--clk_i => clk_64,
		--trig_i => drdy,
		--i_o => lo_mix_i,
		--q_o => lo_mix_q
	--);

	-- mixer
	--mix0: entity work.complex_mul port map(
		--clk_i => clk_64,
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
		--clk_i		=> clk_64,
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
	fifo_in_reg_check <= '1' when unsigned(spi_addr_r)=MOD_IN else '0';

	mod_in_fifo: entity work.fifo_simple
	generic map(
		g_DEPTH => 32,
		g_WIDTH => 16
    )
	port map(
		i_rstn_async => nrst,
		i_clk => clk_64,
		-- FIFO Write Interface
		i_wr_en => fifo_in_reg_check,
		i_wr_data => spi_rx_r(7 downto 0) & spi_rx_r(15 downto 8), -- endianness fix
		o_full => open,
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
	  clk => clk_64,
	  nrst => nrst,
	  fifo_rd_en => fifo_in_rd_en,
	  fifo_rd_data => fifo_in_rd_data,
	  fifo_ae => fifo_in_ae,
	  fifo_empty => fifo_in_empty,
	  m_axis_mod_o => source_axis_out_mod,
	  m_axis_mod_i => source_axis_in_mod
	);

	--debug
	--source_axis_out_mod.tdata <= x"147B";
	--resampler_axis_out_mod.tdata <= x"147B";
	--resampler_axis_out_mod.tvalid <= '1';

	--interpol
	interpol0: entity work.mod_resampler
	port map(
		clk_i => clk_64,
		s_axis_mod_i => source_axis_out_mod,
		s_axis_mod_o => source_axis_in_mod,
		m_axis_mod_o => resampler_axis_out_mod,
		m_axis_mod_i => resampler_axis_in_mod
	);

	-- CTCSS source
	--ctcss_enc0: entity work.ctcss_encoder generic map(
		--SINCOS_RES => 16,
		--SINCOS_ITER	=> 20,
		--SINCOS_COEFF => x"4DB0" --x"4DB9",
	--)
	--port map(
		--clk_i => clk_64,
		--nrst_i => nrst,
		--ctcss_i => regs_rw(CR_2)(7 downto 2),
		--m_axis_mod_i => ctcss_axis_in_mod,
		--m_axis_mod_o => ctcss_axis_out_mod
	--);
	--ctcss_fm_tx <= std_logic_vector(signed(mod_in_r_sync) + signed(ctcss_r));

	-- frequency modulator
	freq_mod0: entity work.fm_modulator
	generic map(
		SINCOS_RES => 16,
		SINCOS_ITER	=> 20,
		SINCOS_COEFF => x"4DB0" --x"4DB9",
	)
	port map(
		clk_i => clk_64,
		nrst_i => nrst,
		nw_i => regs_rw(CR_2)(8),
		s_axis_mod_i => resampler_axis_out_mod,
		s_axis_mod_o => resampler_axis_in_mod,
		m_axis_iq_i => mux_axis_out_iq,
		m_axis_iq_o => freq_mod_axis_in_iq
	);


	-- amplitude modulator
	--ampl_mod0: entity work.am_modulator port map(
		--clk_i => clk_64,
		--mod_i => mod_in_r_sync(14 downto 0) & '0', -- the mod_in_r_sync bus holds signed values only, we need unsigned
		--i_o => i_am_tx,
		--q_o => q_am_tx
	--);

	-- single sideband modulator
	--ssb_id_r <= signed(fifo_in_data_o);
	--ssb_qd_r <= signed(fifo_in_data_o);

	--sb_sel0: entity work.sideband_sel port map(
		--sel => regs_rw(CR_1)(15),
		--d_i => ssb_qd_r,
		--d_o => sel_ssb_qd_r
	--);

	--delay_block0: entity work.delay_block generic map(
		--DELAY => 40
	--)
	--port map(
		--clk_i => clk_64,
		--trig_i => samp_clk,
		--d_i => ssb_id_r,
		--signed(d_o) => i_ssb_tx
	--);

	--hilbert0: entity work.fir_hilbert generic map(
		--TAPS_NUM => 81,
		--SAMP_WIDTH => 16
	--)
	--port map(
		--clk_i => clk_64,
		--trig_i => samp_clk,
		--data_i => sel_ssb_qd_r,
		--std_logic_vector(data_o) => q_ssb_tx,
		--drdy_o => ssb_hilb_rdy
	--);
	--i_ssb_tx_sync <= i_ssb_tx;-- when rising_edge(ssb_hilb_rdy);
	--q_ssb_tx_sync <= q_ssb_tx;-- when rising_edge(ssb_hilb_rdy);

	-- 16QAM modulator
	--symb_clk_div0: entity work.clk_div_block
	--generic map(
		--DIV => 40
	--)
	--port map(
		--clk_i => zero_word,
		--clk_o => symb_clk
	--);

	--rand_symb_source0: entity work.dither_source port map(
		--clk_i => clk_i,
		--ena => '1',
		--trig => symb_clk,
		--out_o => raw_rand
	--);

	--qam_mod0: entity work.qam_16 port map(
		--data_i => mod_in_r(3 downto 0), --std_logic_vector(raw_rand(3 downto 0))
		--i_o => i_qam_tx,
		--q_o => q_qam_tx
	--);

	---- phase modulator
	--pm_mod0: entity work.pm_modulator port map(
		--clk_i => clk_64,
		--mod_i => mod_in_r, --x"0000",
		--i_o => i_pm_tx,
		--q_o => q_pm_tx
	--);

	-- modulation selector
	tx_mod_sel0: entity work.mod_sel port map(
		clk_i => clk_64,
		sel_i => regs_rw(CR_1)(14 downto 12),
		s00_axis_iq_i => freq_mod_axis_in_iq, -- FM
		s01_axis_iq_i => (x"0FFF0000", '1'), -- AM
		s02_axis_iq_i => (x"01FF0000", '1'), -- SSB
		s03_axis_iq_i => (x"7FFF0000", '1'), -- reserved
		s04_axis_iq_i => (x"7FFF0000", '1'), -- reserved
		s00_axis_iq_o => mux_axis_out_iq,
		s01_axis_iq_o => open,
		s02_axis_iq_o => open,
		s03_axis_iq_o => open,
		s04_axis_iq_o => open,
		m_axis_iq_i => unpack_axis_out_iq,
		m_axis_iq_o => mux_axis_in_iq
	);

	-- digital predistortion blocks
	--dpd0: entity work.dpd port map(
		--clk_i => clk_64,
		--p1 => signed(regs_rw(DPD_1)),
		--p2 => signed(regs_rw(DPD_2)),
		--p3 => signed(regs_rw(DPD_3)),
		--i_i => i_raw_tx,
		--q_i => q_raw_tx,
		--i_o => i_dpd_tx,
		--q_o => q_dpd_tx
	--);

	--iq_bal0: entity work.iq_balancer_16 port map(
		--clk_i => clk_64,
		--i_i => i_dpd_tx,
		--q_i => q_dpd_tx,
		--ib_i => regs_rw(I_GAIN),
		--qb_i => regs_rw(Q_GAIN),
		--i_o => i_bal_tx,
		--q_o	=> q_bal_tx
	--);

	--iq_offset0: entity work.iq_offset port map(
		--clk_i => clk_64,
		--i_i => i_bal_tx,
		--q_i => q_bal_tx,
		--ai_i => regs_rw(I_OFFS_NULL),
		--aq_i => regs_rw(Q_OFFS_NULL),
		--i_o => i_offs_tx,
		--q_o => q_offs_tx
	--);

	--iq_fifo_out: entity work.iq_fifo generic map(
		--DEPTH => 8,
		--D_WIDTH => 16
	--)
	--port map(
		--clk_i => clk_64,
		--nrst_i => nrst,
		--trig_i => zero_word,
		--wr_clk_i => zero_word,
		--rd_clk_i => zero_word,
		--i_i => i_offs_tx,
		--q_i => q_offs_tx,
		--i_o => i_out,
		--q_o => q_out
	--);

	unpack0: entity work.unpack port map(
		clk_i => clk_64,
		nrst_i => nrst,
		s_axis_iq_i => mux_axis_in_iq,
		s_axis_iq_o => unpack_axis_out_iq,
		data_o => data_tx_r
	);

	ddr_tx0: ddr_tx port map(
		clk_i => clk_64,
		data_i => data_tx_r,
		rst_i => regs_rw(CR_2)(1) or not regs_rw(CR_2)(0),
		clk_o => clk_tx_o,
		data_o => data_tx_o
	);

	----------------------------------- control etc. ------------------------------------
	spi_slave0: entity work.spi_slave port map(
		miso_o => spi_miso,
		mosi_i => spi_mosi,
		sck_i => spi_sck,
		ncs_i => spi_ncs,
		data_o => spi_rx_r,
		addr_o => spi_addr_r,
		data_i => spi_tx_r,
		nrst => nrst,
		ena => '1',
		rw => spi_rw,
		ld => regs_latch,
		clk_i => clk_64
	);

	ctrl_regs0: entity work.ctrl_regs port map(
		clk_i => clk_64,
		nrst_i => nrst,
		addr_i => spi_addr_r,
		data_i => spi_rx_r,
		data_o => spi_tx_r,
		rw_i => spi_rw,
		latch_i => regs_latch,
		regs_rw => regs_rw,
		regs_r => regs_r
	);

	-- additional connections
	regs_r(SR_1) <= std_logic_vector(to_unsigned(REV_MAJOR, 8)) & std_logic_vector(to_unsigned(REV_MINOR, 8)); -- revision number
	--regs_r(SR_2) <= ; -- PLL lock
	regs_r(SR_3 to SR_7) <= (others => (others => '0'));
	regs_r(DEMOD_OUT) <= (others => '0');

	-- I/Os
	-- automatically select the source of the fifo_ae signal
	mod_fifo_ae <= fifo_in_ae when regs_rw(CR_2)(1 downto 0)="01"
		else fifo_out_ae when regs_rw(CR_2)(1 downto 0)="10"
		else '0';

	-- IO update
	process(clk_64)
	begin
		if rising_edge(clk_64) then
			with regs_rw(CR_1)(11 downto 9) select -- TODO: set this to match the register map
			io3 <= regs_r(SR_2)(0)	when "000",	-- PLL lock flag
			   '0'					when "001",
			   '0'					when "010",
			   '0'					when "011",
			   '0'					when "100",
			   mod_fifo_ae			when "101",	-- baseband FIFO almost empty flag
			   '0'					when others;
			io4 <= mux_axis_out_iq.tready;
			io5 <= freq_mod_axis_in_iq.tvalid;
			io6 <= mux_axis_in_iq.tvalid;
		end if;
	end process;
end magic;
