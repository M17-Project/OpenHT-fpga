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
	-------------------------------------- signals --------------------------------------
	-- 38, 64 and 152 MHz clocks
	signal clk_38, clk_64, clk_152	: std_logic := '0';
	-- 7.2MHz sample clock
	signal clk_7M2					: std_logic := '0';
	
	-- DDR signals
	signal clk_rx09					: std_logic := '0';
	signal clk_rx24					: std_logic := '0';
	signal data_rx09_r				: std_logic_vector(1 downto 0) := (others => '0');
	signal data_rx24_r				: std_logic_vector(1 downto 0) := (others => '0');
	signal data_tx_r				: std_logic_vector(1 downto 0) := (others => '0');
	-- SPI data regs
	signal spi_rw					: std_logic := '0';										-- SPI R/W flag
	signal spi_rx_r, spi_tx_r		: std_logic_vector(15 downto 0) := (others => '0');
	signal spi_addr_r				: std_logic_vector(14 downto 0) := (others => '0');
	-- IQ - RX
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
	-- control registers related
	signal reg_data_wr, reg_data_rd	: std_logic_vector(15 downto 0) := (others => '0');
	signal reg_addr					: std_logic_vector(14 downto 0) := (others => '0');
	signal reg_rw					: std_logic := '0';
	signal regs_rw					: t_rw_regs := (others => (others => '0'));
	signal regs_r					: t_r_regs := (others => (others => '0'));
	
	----------------------------- low level building blocks -----------------------------
	-- main PLL block
	component pll_osc is
		port(
			rstn_i		: in std_logic;						-- reset in (low-active)
			clki_i		: in std_logic;						-- reference input
			clkop_o		: out std_logic;					-- primary output
			clkos_o		: out std_logic;					-- secondary output 1
			clkos2_o	: out std_logic;					-- secondary output 2
			lock_o		: out std_logic						-- lock flag
		);
	end component;
	
	-- sample rate generator PLL block
	component pll_samp is
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
	
	-- IQ deserializer block
	component iq_des is
		port(
			clk_i		: in std_logic;
			ddr_clk_i	: in std_logic;
			data_i		: in std_logic_vector(1 downto 0);
			rst			: in std_logic;
			i_o, q_o	: out std_logic_vector(12 downto 0);
			drdy		: out std_logic
		);
	end component;
	
	-- IQ frame unpack block
	component unpack is
		port(
			clk_i	: in std_logic;
			zero	: in std_logic;							-- send zero words if high
			i_i		: in std_logic_vector(15 downto 0);		-- 16-bit signed, sign at the MSB
			q_i		: in std_logic_vector(15 downto 0);		-- 16-bit signed, sign at the MSB
			data_o	: out std_logic_vector(1 downto 0)
		);
	end component;
	
	-- "zero word" insertion block
	component zero_insert is
		port(
			clk_i	: in std_logic;							-- 64MHz clock in
			runup_i	: in std_logic;							-- set to '1' to send initial zero words to the transceiver
			s_o 	: out std_logic							-- zero word out ('1' = send zero words)
		);
	end component;
	
	------------------------------------ DSP blocks -------------------------------------
	-- decimation block
	component decim is
		generic(
			DECIM		: integer := 10;
			BIT_SIZE	: integer := 16
		);
		port(
			clk_i					: in std_logic;						-- fast clock in
			i_data_i, q_data_i		: in signed(BIT_SIZE-1 downto 0);	-- data in
			i_data_o, q_data_o		: out signed(BIT_SIZE-1 downto 0);	-- data out
			trig_i					: in std_logic;						-- trigger in
			drdy_o					: out std_logic						-- data ready out
		);
	end component;
	
	-- clock divider
	component clk_div_block is
		generic(
			DIV		: integer := 40
		);
		port(
			clk_i	: in std_logic;							-- fast clock in
			clk_o	: inout std_logic						-- slow clock out
		);
	end component;
	
	-- 16-bit add const block
	component add_const is
		port(
			data_i		: in signed(15 downto 0);			-- data in
			data_o		: out std_logic_vector(15 downto 0)	-- data out
		);
	end component;
	
	-- local oscillator (40kHz, complex sincos)
	component local_osc is
		generic(
			DIV			: integer := 10 					-- for a sample rate of 400k, this gives 40k
		);
		port(
			clk_i	: in std_logic;
			trig_i	: in std_logic;
			i_o		: out signed(15 downto 0);
			q_o		: out signed(15 downto 0)
		);
	end component;
	
	-- complex multiplier block
	component complex_mul is
		port(
			a_re, a_im, b_re, b_im	: in signed(15 downto 0);
			c_re, c_im				: out signed(15 downto 0)
		);
	end component;
	
	-- channel FIR filter
	component fir_channel is
		port(
			clk_i		: in std_logic;						-- fast clock in
			data_i		: in signed(15 downto 0);			-- data in
			data_o		: out signed(15 downto 0);			-- data out
			trig_i		: in std_logic;						-- trigger in
			drdy_o		: out std_logic						-- data ready out
		);
	end component;
	
	-- Hilbert transformer
	component fir_hilbert is
		generic(
			TAPS_NUM : integer := 81
		);
		port(
			clk_i		: in std_logic;						-- fast clock in
			data_i		: in signed(15 downto 0);			-- data in
			data_o		: out signed(15 downto 0);			-- data out
			trig_i		: in std_logic;						-- trigger in
			drdy_o		: out std_logic						-- data ready out
		);
	end component;
	
	-- Root Raised Cosine filter
	--component fir_rrc is
		--generic(
			--TAPS_NUM : integer := 81
		--);
		--port(
			--clk_i			: in std_logic;					-- fast clock in
			--data_i		: in signed(15 downto 0);		-- data in
			--data_o		: out signed(15 downto 0);		-- data out
			--trig_i		: in std_logic;					-- trigger in
			--drdy_o		: out std_logic					-- data ready out
		--);
	--end component;
	
	-- delay block
	component delay_block is
		generic(
			DELAY		: integer := 40
		);
		port(
			clk_i	: in std_logic;							-- fast clock in
			d_i		: in signed(15 downto 0);				-- data in
			d_o		: out signed(15 downto 0);				-- data out
			trig_i	: in std_logic							-- trigger in
		);
	end component;
	
	-- magnitude estimator, |z| = sqrt(i^2 + q^2)
	component mag_est is
		port(
			clk_i		: in std_logic;
			trig_i		: in std_logic;
			i_i, q_i	: in signed(15 downto 0);
			est_o		: out unsigned(15 downto 0);
			rdy_o		: out std_logic
		);
	end component;
	
	-- polynomial digital predistortion block
	component dpd is
		port(
			p1 : in signed(15 downto 0);
			p2 : in signed(15 downto 0);
			p3 : in signed(15 downto 0);
			i_i : in std_logic_vector(15 downto 0);
			q_i : in std_logic_vector(15 downto 0);
			i_o: out std_logic_vector(15 downto 0);
			q_o: out std_logic_vector(15 downto 0)
		);
	end component;
	
	-- IQ balancing
	component iq_balancer_16 is
		port(
			i_i		: in std_logic_vector(15 downto 0);		-- I data in
			q_i		: in std_logic_vector(15 downto 0);		-- Q data in
			ib_i	: in std_logic_vector(15 downto 0);		-- I balance in, 0x4000 = "+1.0"
			qb_i	: in std_logic_vector(15 downto 0);		-- Q balance in, 0x4000 = "+1.0"
			i_o		: out std_logic_vector(15 downto 0);	-- I data in
			q_o		: out std_logic_vector(15 downto 0)		-- Q data in
		);
	end component;
	
	-- IQ offset null
	component iq_offset is
		port(
			i_i : in std_logic_vector(15 downto 0);
			q_i : in std_logic_vector(15 downto 0);
			ai_i : in std_logic_vector(15 downto 0);
			aq_i : in std_logic_vector(15 downto 0);
			i_o : out std_logic_vector(15 downto 0);
			q_o : out std_logic_vector(15 downto 0)
		);
	end component;
	
	-- CTCSS tone generator
	component ctcss_encoder is
		port(
			nrst	: in std_logic;							-- reset
			trig_i	: in std_logic;							-- trigger input, 400k
			clk_i	: in std_logic;							-- main clock
			ctcss_i	: in std_logic_vector(5 downto 0);		-- CTCSS code in
			ctcss_o	: out std_logic_vector(15 downto 0)		-- CTCSS tone out
		);
	end component;
	
	------------------------------------ modulators -------------------------------------
	-- dither source
	component dither_source is
		port(
			clk_i	: in  std_logic;
			ena		: in std_logic;
			trig	: in std_logic := '0';
			out_o	: out signed(15 downto 0)
		);
	end component;
	
	-- frequency modulator
	component fm_modulator is
		port(
			nrst	: in std_logic;							-- reset
			clk_i	: in std_logic;							-- main clock
			mod_i	: in std_logic_vector(15 downto 0);		-- modulation in
			dith_i	: in signed(15 downto 0);				-- phase dither input
			i_o		: out std_logic_vector(15 downto 0);	-- I data out
			q_o		: out std_logic_vector(15 downto 0)		-- Q data out
		);
	end component;
	
	-- amplitude modulator
	component am_modulator is
		port(
			mod_i	: in std_logic_vector(15 downto 0);		-- modulation in
			i_o		: out std_logic_vector(15 downto 0);	-- I data out
			q_o		: out std_logic_vector(15 downto 0)		-- Q data out
		);
	end component;
	
	-- QAM16 modulator
	component qam_16 is
		port(
			data_i		: in  std_logic_vector(3 downto 0);
			i_o, q_o	: out std_logic_vector(15 downto 0)
		);
	end component;
	
	-- phase modulator
	component pm_modulator is
		port(
			mod_i	: in std_logic_vector(15 downto 0);		-- modulation in
			i_o		: out std_logic_vector(15 downto 0);	-- I data out
			q_o		: out std_logic_vector(15 downto 0)		-- Q data out
		);
	end component;
	
	----------------------------------- demodulators ------------------------------------
	-- frequency demodulator
	component freq_demod is
		port(
			clk_i		: in std_logic;				-- demod clock
			i_i, q_i	: in signed(15 downto 0);	-- I/Q inputs
			demod_o		: out signed(15 downto 0)	-- freq demod out
		);
	end component;

	-- amplitude demodulator is the 'mag_est' block
	
	-------------------------------------- control --------------------------------------
	-- control registers
	component ctrl_regs is
		port(
			clk_i		: in std_logic;							-- clock in
			nrst		: in std_logic;							-- reset
			addr_i		: in std_logic_vector(14 downto 0);		-- address in
			data_i		: in std_logic_vector(15 downto 0);		-- data in
			data_o		: out std_logic_vector(15 downto 0);	-- data out
			rw_i		: in std_logic;							-- read/write flag, r:0 w:1
			latch_i		: in std_logic;							-- latch signal (rising edge)
			-- registers
			regs_rw		: inout t_rw_regs;
			regs_r		: in t_r_regs
		);
	end component;
	
	-- sideband selector
	component sideband_sel is
		port(
			sel			: in std_logic;							-- sideband selector (0-USB, 1-LSB)
			d_i			: in signed(15 downto 0);				-- I data out
			d_o			: out signed(15 downto 0)				-- Q data out
		);
	end component;
	
	-- modulation selector
	component mod_sel is
		port(
			sel			: in std_logic_vector(2 downto 0);		-- mod selector
			i0_i, q0_i	: in std_logic_vector(15 downto 0);		-- input 0
			i1_i, q1_i	: in std_logic_vector(15 downto 0);		-- input 1
			i2_i, q2_i	: in std_logic_vector(15 downto 0);		-- input 2
			i3_i, q3_i	: in std_logic_vector(15 downto 0);		-- input 3
			i4_i, q4_i	: in std_logic_vector(15 downto 0);		-- input 4
			i_o			: out std_logic_vector(15 downto 0);	-- I data out
			q_o			: out std_logic_vector(15 downto 0)		-- Q data out
		);
	end component;
	
	------------------------------------ interfaces -------------------------------------
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
	------------------------------------- port maps -------------------------------------
	pll0: pll_osc port map(
		rstn_i => not rst,
		clki_i => clk_i,
		clkop_o => clk_152,
		clkos_o => clk_64,
		clkos2_o => clk_38,
		lock_o => regs_r(1)(0)
	);
	
	pll1: pll_samp port map(
		rstn_i => not rst,
		clki_i => clk_i,
		clkop_o => clk_7M2,
		lock_o => regs_r(1)(1)
	);
	
	---------------------------------------- RX -----------------------------------------
	-- sub-GHz receiver
	ddr_rx0: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx09_i,
		rst_i => (regs_rw(1)(0) and not regs_rw(1)(1)) or (not regs_rw(0)(0)), -- check if STATE=RX and the band is correct
		sclk_o => clk_rx09,
		data_o => data_rx09_r
	);
	
	-- 2.4 GHz receiver
	ddr_rx1: ddr_rx port map(
		clk_i => clk_rx_i,
		data_i => data_rx24_i,
		rst_i =>  (regs_rw(1)(0) and not regs_rw(1)(1)) or (not regs_rw(0)(1)), -- check if STATE=RX and the band is correct
		sclk_o => clk_rx24,
		data_o => data_rx24_r
	);
	
	iq_des0: iq_des port map(
		clk_i => clk_152,
		ddr_clk_i => clk_rx09 or clk_rx24,		-- TODO: check if this actually works!
		data_i => data_rx09_r or data_rx24_r,	-- ...this too. otherwise add a switch block
		rst => not regs_rw(1)(1),
		i_o => i_r,
		q_o => q_r,
		drdy => drdy
	);
	
	lo0: local_osc port map(
		clk_i => clk_38,
		trig_i => drdy,
		i_o => lo_mix_i,
		q_o => lo_mix_q
	);
	
	mix0: complex_mul port map(
		a_re => signed(i_r & '0' & '0' & '0'), -- somehow concatenating with "000" didn't work here
		a_im => signed(q_r & '0' & '0' & '0'),
		b_re => lo_mix_i,
		b_im => lo_mix_q,
		c_re => mix_i_o,
		c_im => mix_q_o
	);
	
	i_fir_ser0: fir_channel port map(
		clk_i => clk_38,
		data_i => mix_i_o,
		data_o => flt_i,
		trig_i => drdy,
		drdy_o => flt_i_rdy
	);
	
	q_fir_ser0: fir_channel port map(
		clk_i => clk_38,
		data_i => mix_q_o,
		data_o => flt_q,
		trig_i => drdy,
		drdy_o => flt_q_rdy
	);
	
	decim0: decim port map(
		clk_i => clk_i,
		i_data_i => flt_i,
		q_data_i => flt_q,
		i_data_o => flt_id_r,
		q_data_o => flt_qd_r,
		trig_i => flt_i_rdy and flt_q_rdy,
		drdy_o => drdyd
	);
	
	am_demod0: mag_est port map(
		clk_i => clk_38,
		trig_i => drdyd,
		i_i => flt_id_r,
		q_i => flt_qd_r,
		est_o => am_demod_raw,
		rdy_o => am_demod_rdy
	);
	
	fm_demod0: freq_demod port map(
		clk_i => drdyd,
		i_i => flt_id_r,
		q_i => flt_qd_r,
		demod_o => fm_demod_raw
	);
	
	---------------------------------------- TX -----------------------------------------
	-- frequency modulator
	dither_source0: dither_source port map(
		clk_i => clk_i,
		ena => regs_rw(0)(5),
		trig => zero_word,
		out_o => fm_dith_r
	);
	
	ctcss_enc0: ctcss_encoder port map(
		nrst => not rst,
		trig_i => zero_word,
		clk_i => clk_i,
		ctcss_i => regs_rw(1)(7 downto 2),
		ctcss_o	=> ctcss_r
	);
	ctcss_fm_tx <= std_logic_vector(signed(regs_rw(9)) + signed(ctcss_r));
	
	freq_mod0: fm_modulator port map(
		nrst => not rst,
		clk_i => clk_38,
		mod_i => ctcss_fm_tx,
		dith_i => fm_dith_r,
		i_o => i_fm_tx,
		q_o => q_fm_tx
	);
	
	-- amplitude modulator
	ampl_mod0: am_modulator port map(
		mod_i => regs_rw(9),
		i_o => i_am_tx,
		q_o => q_am_tx
	);
	
	-- single sideband modulator
	-- TODO: it's a sampler, actually
	decim1: decim port map(
		clk_i => clk_i,
		i_data_i => signed(regs_rw(9)), -- I branch is the input signal
		q_data_i => signed(regs_rw(9)), -- Q branch is the Hilbert-transformed input signal
		i_data_o => ssb_id_r,
		q_data_o => ssb_qd_r,
		trig_i => zero_word, -- 400kHz
		drdy_o => ssb_rdy
	);
	
	sb_sel0: sideband_sel port map(
		sel => regs_rw(0)(15),
		d_i => ssb_qd_r,
		d_o => sel_ssb_qd_r
	);
	
	delay_block0: delay_block port map(
		clk_i => clk_i,
		d_i => ssb_id_r,
		signed(d_o) => i_ssb_tx,
		trig_i => ssb_rdy
	);
	
	hilbert0: fir_hilbert port map(
		clk_i => clk_38,
		data_i => signed(sel_ssb_qd_r),
		std_logic_vector(data_o) => q_ssb_tx,
		trig_i => ssb_rdy
		--drdy_o => ssb_hilb_rdy
	);
	
	-- 16QAM modulator
	--symb_clk_div0: clk_div_block port map(
		--clk_i => zero_word,
		--clk_o => symb_clk
	--);
	
	--rand_symb_source0: dither_source port map(
		--clk_i => clk_i,
		--ena => '1',
		--trig => symb_clk,
		--out_o => raw_rand
	--);
	
	qam_mod0: qam_16 port map(
		data_i => regs_rw(9)(3 downto 0), --std_logic_vector(raw_rand(3 downto 0))
		i_o => i_qam_tx,
		q_o => q_qam_tx
	);
	
	-- phase modulator
	pm_mod0: pm_modulator port map(
		mod_i => regs_rw(9), --x"0000",
		i_o => i_pm_tx,
		q_o => q_pm_tx
	);
	
	-- modulation selector
	tx_mod_sel0: mod_sel port map(
		sel => regs_rw(0)(14 downto 12),
		i0_i => i_fm_tx, --FM
		q0_i => q_fm_tx,
		i1_i => i_am_tx, --AM
		q1_i => q_am_tx,
		i2_i => i_ssb_tx, --SSB
		q2_i => q_ssb_tx,
		i3_i => i_pm_tx, --invalid (used for PM for now)
		q3_i => q_pm_tx,
		i4_i => x"7FFF", -- invalid
		q4_i => x"0000",
		i_o => i_raw_tx,
		q_o => q_raw_tx
	);

	-- digital predistortion blocks
	dpd0: dpd port map(
		p1 => signed(regs_rw(6)),
		p2 => signed(regs_rw(7)),
		p3 => signed(regs_rw(8)),
		i_i => i_raw_tx,
		q_i => q_raw_tx,
		i_o => i_dpd_tx,
		q_o => q_dpd_tx
	);
	
	iq_bal0: iq_balancer_16 port map(
		i_i => i_dpd_tx,
		q_i => q_dpd_tx,
		ib_i => regs_rw(4),
		qb_i => regs_rw(5),
		i_o => i_bal_tx,
		q_o	=> q_bal_tx
	);
	
	iq_offset0: iq_offset port map(
		i_i => i_bal_tx,
		q_i => q_bal_tx,
		ai_i => regs_rw(2),
		aq_i => regs_rw(3),
		i_o => i_offs_tx,
		q_o => q_offs_tx
	);

	-- DDR TX queue
	zero_insert0: zero_insert port map(
		clk_i => clk_64,
		runup_i => rst,
		s_o => zero_word
	);
	
	unpack0: unpack port map(
		clk_i => clk_64,
		zero => zero_word,
		i_i => i_offs_tx,
		q_i => q_offs_tx,
		data_o => data_tx_r
	);	
	
	ddr_tx0: ddr_tx port map(
		clk_i => clk_64,
		data_i => data_tx_r,
		rst_i => regs_rw(1)(1) or not regs_rw(1)(0),
		clk_o => clk_tx_o,
		data_o => data_tx_o
	);
	
	----------------------------------- control etc. ------------------------------------
	spi_slave0: spi_slave port map(
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
	
	ctrl_regs0: ctrl_regs port map(
		clk_i => clk_i,
		nrst => not rst,
		addr_i => spi_addr_r,
		data_i => spi_rx_r,
		data_o => spi_tx_r,
		rw_i => spi_rw,
		latch_i => spi_ncs,
		regs_rw => regs_rw,
		regs_r => regs_r
	);
	
	-- additional connections
	regs_r(0) <= x"4854";
	--regs_r(1) <= 
	regs_r(2) <= std_logic_vector(fm_demod_raw); -- TODO: change this according to the reg map
	regs_r(3) <= std_logic_vector(am_demod_raw); -- TODO: change this according to the reg map
	regs_r(4) <= std_logic_vector(flt_id_r);
	regs_r(5) <= std_logic_vector(flt_qd_r);
end magic;
