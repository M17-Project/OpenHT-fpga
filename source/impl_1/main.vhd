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

entity main_all is
	generic(
		REV_MAJOR			: std_logic_vector(7 downto 0) := x"00";
		REV_MINOR			: std_logic_vector(7 downto 0) := x"01"
	);
	port(
		-- 26 MHz clock input from the AT86
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
	signal clk_rx09					: std_logic := '0';
	signal clk_rx24					: std_logic := '0';
	signal data_rx09_r				: std_logic_vector(1 downto 0) := (others => '0');
	signal data_rx24_r				: std_logic_vector(1 downto 0) := (others => '0');
	signal data_tx_r				: std_logic_vector(1 downto 0) := (others => '0');
	-- SPI data regs
	signal spi_rw					: std_logic := '0';									-- SPI R/W flag
	signal spi_rx_r, spi_tx_r		: std_logic_vector(15 downto 0) := (others => '0');
	signal spi_addr_r				: std_logic_vector(13 downto 0) := (others => '0');
	-- IQ - RX
	signal des_inp					: std_logic_vector(1 downto 0) := (others => '0');
	signal i_r_pre, q_r_pre			: std_logic_vector(12 downto 0) := (others => '0');	-- raw 13-bit I/Q samples from the deserializer
	signal i_r, q_r					: std_logic_vector(12 downto 0) := (others => '0');
	signal i_d, q_d					: signed(12 downto 0) := (others => '0');
	signal i_raw, q_raw				: signed(12 downto 0) := (others => '0');
	signal drdy, drdyd				: std_logic := '0';
	signal lo_mix_i, lo_mix_q		: signed(15 downto 0) := (others => '0');
	signal mix_i_o, mix_q_o			: signed(15 downto 0) := (others => '0');
	signal flt_i, flt_q				: signed(15 downto 0) := (others => '0');
	signal flt_i_r, flt_q_r			: signed(15 downto 0) := (others => '0');
	signal flt_id_r, flt_qd_r		: signed(15 downto 0) := (others => '0');
	signal am_demod_raw				: unsigned(15 downto 0) := (others => '0');
	signal fm_demod_raw				: signed(15 downto 0) := (others => '0');
	signal fm_demod_slv				: std_logic_vector(15 downto 0) := (others => '0');
	signal flt_i_rdy, flt_q_rdy		: std_logic := '0';
	signal am_demod_rdy				: std_logic := '0';
	signal rssi_rdy					: std_logic := '0';
	signal rssi_r					: unsigned(15 downto 0) := (others => '0');
	--signal mag_sq_r					: std_logic_vector(31 downto 0) := (others => '0');
	-- IQ - TX
	signal zero_word				: std_logic := '0';
	signal i_fm_tx, q_fm_tx			: std_logic_vector(15 downto 0) := (others => '0');
	signal i_am_tx, q_am_tx			: std_logic_vector(15 downto 0) := (others => '0');
	signal i_ssb_tx, q_ssb_tx		: std_logic_vector(15 downto 0) := (others => '0');
	signal i_pm_tx, q_pm_tx			: std_logic_vector(15 downto 0) := (others => '0');
	signal i_qam_tx, q_qam_tx		: std_logic_vector(15 downto 0) := (others => '0');
	signal ctcss_r					: std_logic_vector(15 downto 0) := (others => '0');
	signal ctcss_fm_tx				: std_logic_vector(15 downto 0) := (others => '0');
	signal ssb_id_r, ssb_qd_r		: signed(15 downto 0) := (others => '0');
	signal sel_ssb_qd_r				: signed(15 downto 0) := (others => '0');
	signal ssb_rdy					: std_logic := '0';
	signal i_raw_tx, q_raw_tx		: std_logic_vector(15 downto 0) := (others => '0');
	signal i_dpd_tx, q_dpd_tx		: std_logic_vector(15 downto 0) := (others => '0');
	signal i_bal_tx, q_bal_tx		: std_logic_vector(15 downto 0) := (others => '0');
	signal i_offs_tx, q_offs_tx		: std_logic_vector(15 downto 0) := (others => '0');
	signal fm_dith_r				: signed(15 downto 0) := (others => '0');
	signal pm_mod					: std_logic_vector(15 downto 0) := (others => '0');
	signal mod_in_r					: std_logic_vector(15 downto 0) := (others => '0');
	signal mod_in_r_sync			: std_logic_vector(15 downto 0) := (others => '0');
	--signal symb_clk					: std_logic := '0';
	-- control registers related
	signal reg_data_wr, reg_data_rd	: std_logic_vector(15 downto 0) := (others => '0');
	signal reg_addr					: std_logic_vector(14 downto 0) := (others => '0');
	signal reg_rw					: std_logic := '0';
	signal regs_rw					: t_rw_regs := (others => (others => '0'));
	signal regs_r					: t_r_regs := (others => (others => '0'));
	signal regs_latch				: std_logic := '0';
	--FIFOs
	signal samp_clk					: std_logic := '0';
	signal bsb_fifo_ae				: std_logic := '0';
	signal fifo_in_data_i			: std_logic_vector(15 downto 0) := (others => '0');
	signal fifo_in_data_o			: std_logic_vector(15 downto 0) := (others => '0');
	signal fifo_in_ae				: std_logic := '0';
	signal fifo_in_en				: std_logic := '0';
	signal fifo_in_en_sync			: std_logic := '0';
	signal fifo_in_empty			: std_logic := '0';
	signal fifo_in_full				: std_logic := '0';
	--signal fifo_in_rd_clk			: std_logic := '0';
	--signal fifo_in_wr_clk			: std_logic := '0';
	signal fifo_out_ae				: std_logic := '0';
	signal fifo_i_ae, fifo_q_ae		: std_logic := '0';
	signal fifo_iq_clk_en			: std_logic := '0';
	signal fifo_iq_rdy				: std_logic := '0';
	signal i_out, q_out				: std_logic_vector(15 downto 0) := (others => '0');
	
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
	
	--component fifo_in_samples is
		--port(
			--wr_clk_i: in std_logic;
			--rd_clk_i: in std_logic;
			--rst_i: in std_logic;
			--rp_rst_i: in std_logic;
			--wr_en_i: in std_logic;
			--rd_en_i: in std_logic;
			--wr_data_i: in std_logic_vector(15 downto 0);
			--full_o: out std_logic;
			--empty_o: out std_logic;
			--almost_empty_o: out std_logic;
			--rd_data_o: out std_logic_vector(15 downto 0)
		--);
	--end component;
	
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
	ddr_rx0: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx09_i,
		rst_i => (regs_rw(CR_2)(0) and not regs_rw(CR_2)(1)) or (regs_rw(CR_1)(0)), -- check if STATE=RX and the band is correct
		sclk_o => clk_rx09,
		data_o => data_rx09_r
	);
	
	-- 2.4 GHz receiver
	ddr_rx1: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx24_i,
		rst_i =>  (regs_rw(CR_2)(0) and not regs_rw(CR_2)(1)) or (not regs_rw(CR_1)(0)), -- check if STATE=RX and the band is correct
		sclk_o => clk_rx24,
		data_o => data_rx24_r
	);
	
	-- IQ stream deserializer
	--des_inp <= data_rx09_r or data_rx24_r; -- crude, but works
	des_inp <= data_rx09_r when regs_rw(CR_1)(1 downto 0)="00"
		else data_rx24_r when regs_rw(CR_1)(1 downto 0)="01"
		else (others => '0');
	deserializer0: entity work.iq_des port map(
		clk_i		=> clk_64,
		ddr_clk_i	=> clk_rx09,
		data_i		=> des_inp,
		nrst		=> nrst,
		i_o			=> i_r_pre,
		q_o			=> q_r_pre,
		drdy		=> drdy
	);
	
	-- FIFOs
	--fifo_iq_rdy <= (not fifo_i_ae) and (not fifo_q_ae);
	--process(fifo_iq_rdy)
	--begin
		--if nrst='1' then
			--if rising_edge(fifo_iq_rdy) then
				--fifo_iq_clk_en <= '1';
			--end if;
		--else
			--fifo_iq_clk_en <= '0';
		--end if;
	--end process;
	--i_fifo: entity work.fifo_dc generic map(
		--DEPTH => 8,
		--D_WIDTH => 13
	--)
	--port map(
		--wr_clk_i => drdy,
        --rd_clk_i => drdy and fifo_iq_clk_en,
        --data_i => i_r_pre,
        --data_o => i_r,
        --fifo_ae => fifo_i_ae,
		--fifo_full => open,
		--fifo_empty => open
	--);
	
	--q_fifo: entity work.fifo_dc generic map(
		--DEPTH => 8,
		--D_WIDTH => 13
	--)
	--port map(
		--wr_clk_i => drdy,
        --rd_clk_i => drdy and fifo_iq_clk_en,
        --data_i => q_r_pre,
        --data_o => q_r,
        --fifo_ae => fifo_q_ae,
		--fifo_full => open,
		--fifo_empty => open
	--);
	
	iq_fifo_in: entity work.iq_fifo generic map(
		DEPTH => 8,
		D_WIDTH => 13
	)
	port map(
		clk_i => clk_64,
		nrst_i => nrst,
		trig_i => drdy,
		wr_clk_i => drdy,
		rd_clk_i => drdy,
		i_i => i_r_pre,
		q_i => q_r_pre,
		i_o => i_r,
		q_o => q_r
	);
	
	-- local oscillator, 40kHz
	lo0: entity work.local_osc port map(
		clk_i => clk_64,
		trig_i => drdy,
		i_o => lo_mix_i,
		q_o => lo_mix_q
	);
	
	-- mixer
	mix0: entity work.complex_mul port map(
		clk_i => clk_64, 
		a_re => signed(i_r(11 downto 0) & '0' & '0' & '0' & '0'), -- a gain of 2
		a_im => signed(q_r(11 downto 0) & '0' & '0' & '0' & '0'), -- somehow concatenating with "0000" didn't work here
		b_re => lo_mix_i,
		b_im => lo_mix_q,
		c_re => mix_i_o,
		c_im => mix_q_o
	);
	
	channel_flt0: entity work.channel_filter
	generic map(
		SAMP_WIDTH => 16
	)
	port map(
		clk_i		=> clk_64,
		ch_width	=> regs_rw(CR_2)(10 downto 9),
		i_i			=> mix_i_o,
		q_i			=> mix_q_o,
		i_o			=> flt_id_r,
		q_o			=> flt_qd_r,
		trig_i		=> drdy,
		drdy_o		=> drdyd
	);
	
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
	
	---------------------------------------- TX -----------------------------------------
	-- frequency modulator
	dither_source0: entity work.dither_source port map(
		clk_i => clk_64,
		ena => regs_rw(CR_1)(5),
		trig_i => zero_word,
		out_o => fm_dith_r
	);
	
	ctcss_enc0: entity work.ctcss_encoder port map(
		nrst => nrst,
		trig_i => zero_word,
		ctcss_i => regs_rw(CR_2)(7 downto 2),
		ctcss_o	=> ctcss_r
	);
	ctcss_fm_tx <= std_logic_vector(signed(mod_in_r_sync) + signed(ctcss_r));
	
	freq_mod0: entity work.fm_modulator
	generic map(
		SINCOS_RES => 10
	)
	port map(
		nrst => nrst,
		trig_i => zero_word,
		mod_i => ctcss_fm_tx,
		dith_i => fm_dith_r,
		nw_i => regs_rw(CR_2)(8),
		i_o => i_fm_tx,
		q_o => q_fm_tx
	);
	
	-- amplitude modulator
	ampl_mod0: entity work.am_modulator port map(
		mod_i => mod_in_r_sync,
		i_o => i_am_tx,
		q_o => q_am_tx
	);
	
	-- single sideband modulator
	-- TODO: it's a sampler, actually
	--decim0: entity work.decim port map(
		--clk_i => clk_64,
		--i_data_i => signed(mod_in_r), -- I branch is the input signal
		--q_data_i => signed(mod_in_r), -- Q branch is the Hilbert-transformed input signal
		--i_data_o => ssb_id_r,
		--q_data_o => ssb_qd_r,
		--trig_i => zero_word, -- 400kHz
		--drdy_o => ssb_rdy
	--);
	
	--sb_sel0: entity work.sideband_sel port map(
		--sel => regs_rw(CR_1)(15),
		--d_i => ssb_qd_r,
		--d_o => sel_ssb_qd_r
	--);
	
	--delay_block0: entity work.delay_block port map(
		--clk_i => clk_64,
		--d_i => ssb_id_r,
		--signed(d_o) => i_ssb_tx,
		--trig_i => ssb_rdy
	--);
	
	--hilbert0: entity work.fir_hilbert port map(
		--clk_i => clk_64,
		--data_i => signed(sel_ssb_qd_r),
		--std_logic_vector(data_o) => q_ssb_tx,
		--trig_i => ssb_rdy
		----drdy_o => ssb_hilb_rdy
	--);
	
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
		clk_i => zero_word,
		sel => regs_rw(CR_1)(14 downto 12),
		i0_i => i_fm_tx, --FM
		q0_i => q_fm_tx,
		i1_i => i_am_tx, --AM
		q1_i => q_am_tx,
		i2_i => i_ssb_tx, --SSB
		q2_i => q_ssb_tx,
		i3_i => i_pm_tx, --invalid (used for PM for now)
		q3_i => q_pm_tx,
		i4_i => regs_rw(16#B#),--x"7FFF", -- invalid
		q4_i => regs_rw(16#C#),--x"0000",
		i_o => i_raw_tx,
		q_o => q_raw_tx
	);

	-- digital predistortion blocks
	dpd0: entity work.dpd port map(
		clk_i => zero_word,
		p1 => signed(regs_rw(DPD_1)),
		p2 => signed(regs_rw(DPD_2)),
		p3 => signed(regs_rw(DPD_3)),
		i_i => i_raw_tx,
		q_i => q_raw_tx,
		i_o => i_dpd_tx,
		q_o => q_dpd_tx
	);
	
	iq_bal0: entity work.iq_balancer_16 port map(
		clk_i => zero_word,
		i_i => i_dpd_tx,
		q_i => q_dpd_tx,
		ib_i => regs_rw(I_GAIN),
		qb_i => regs_rw(Q_GAIN),
		i_o => i_bal_tx,
		q_o	=> q_bal_tx
	);
	
	iq_offset0: entity work.iq_offset port map(
		clk_i => zero_word,
		i_i => i_bal_tx,
		q_i => q_bal_tx,
		ai_i => regs_rw(I_OFFS_NULL),
		aq_i => regs_rw(Q_OFFS_NULL),
		i_o => i_offs_tx,
		q_o => q_offs_tx
	);
	
	iq_fifo_out: entity work.iq_fifo generic map(
		DEPTH => 8,
		D_WIDTH => 16
	)
	port map(
		clk_i => clk_64,
		nrst_i => nrst,
		trig_i => zero_word,
		wr_clk_i => zero_word,
		rd_clk_i => zero_word,
		i_i => i_offs_tx,
		q_i => q_offs_tx,
		i_o => i_out,
		q_o => q_out
	);
	
	unpack0: entity work.unpack port map(
		clk_i => clk_64,
		i_i => i_out,
		q_i => q_out,
		req_o => zero_word,
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
		nrst => nrst,
		addr_i => spi_addr_r,
		data_i => spi_rx_r,
		data_o => spi_tx_r,
		rw_i => spi_rw,
		latch_i => regs_latch,
		regs_rw => regs_rw,
		regs_r => regs_r
	);
	
	clk_div_in_samp: entity work.clk_div_block
	generic map(
		DIV => 400/8
	)
	port map(
		clk_i => zero_word,
		clk_o => samp_clk
	);

	mod_in_r <= fifo_in_data_o when regs_rw(CR_2)(11)='1' else regs_rw(MOD_IN);
	mod_in_r_sync <= mod_in_r;-- when rising_edge(zero_word);
	fifo_in_en <= '1' when unsigned(spi_addr_r)=MOD_IN else '0';
	fifo_in_en_sync <= fifo_in_en;-- when rising_edge(clk_64);
	
	--fifo_in_wr_clk <= regs_latch and not fifo_in_full;
	--fifo_in_rd_clk <= samp_clk and not fifo_in_empty;
	
	--fifo_input: fifo_in_samples port map(
		--wr_clk_i => regs_latch,
		--rd_clk_i => samp_clk,
		--rst_i => not nrst,
		--rp_rst_i => '0',
		--wr_en_i => fifo_in_en_sync,-- and not fifo_in_full,
		--rd_en_i => '1',--not fifo_in_empty,
		--wr_data_i => spi_rx_r(7 downto 0) & spi_rx_r(15 downto 8), -- endianness fix
		--full_o => fifo_in_full,
		--empty_o => fifo_in_empty,
		--almost_empty_o => fifo_in_ae,
		--rd_data_o => fifo_in_data_o
	--);
	
	fifo_bsb_in: entity work.fifo_dc generic map(
		DEPTH => 32,
		D_WIDTH => 16
	)
	port map(
		wr_clk_i => regs_latch,
        rd_clk_i => samp_clk,
		--wr_en_i => fifo_in_en_sync, -- and not fifo_in_full,
		--rd_en_i => not fifo_in_empty,
        data_i => spi_rx_r(7 downto 0) & spi_rx_r(15 downto 8), -- endianness fix
        data_o => fifo_in_data_o,
        fifo_ae => fifo_in_ae,
		fifo_full => open, --fifo_in_full,
		fifo_empty => open --fifo_in_empty
	);
	
	-- additional connections
	regs_r(SR_1) <= REV_MAJOR & REV_MINOR; -- revision number
	--regs_r(SR_2) <= ;
	with regs_rw(CR_1)(4 downto 2) select
		regs_r(DEMOD_REG) <= std_logic_vector(fm_demod_raw)		when "000", -- frequency demodulator
		std_logic_vector(am_demod_raw)							when "001", -- amplitude ----//-----
		(others => '0')											when "010", -- SSB (placeholder)
		(others => '0')											when others;
	--regs_r(RSSI_REG) <= ;
	--regs_r(I_RAW_REG) <= i_r & "000";
	--regs_r(Q_RAW_REG) <= q_r & "000";
	--regs_r(I_FLT_REG) <= std_logic_vector(flt_id_r);
	--regs_r(Q_FLT_REG) <= std_logic_vector(flt_qd_r);
	
	-- I/Os
	-- automatically select the source of the fifo_ae signal
	bsb_fifo_ae <= fifo_in_ae when regs_rw(CR_2)(1 downto 0)="01"
		else fifo_out_ae when regs_rw(CR_2)(1 downto 0)="10"
		else '0';
	
	-- IO mux
	process(clk_64)
	begin
		if rising_edge(clk_64) then
			with regs_rw(CR_1)(11 downto 9) select -- TODO: set this to match the register map
			io3 <= regs_r(SR_2)(0)	when "000",	-- PLL lock flag
			   '0'					when "001",
			   '0'					when "010",
			   '0'					when "011",
			   '0'					when "100",
			   bsb_fifo_ae			when "101",	-- baseband FIFO almost empty flag
			   '1'					when others;
			io4 <= drdyd;
			io5 <= '0';
			io6 <= '0';
		end if;
	end process;
end magic;
