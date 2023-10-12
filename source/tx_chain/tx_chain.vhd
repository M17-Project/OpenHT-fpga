-------------------------------------------------------------
-- TX chain
--
-- Sebastien Van Cauwenberghe, ON4SEB
-- Wojciech Kaczmarski, SP5WWP
--
-- M17 Project
-- September 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;
use work.regs_pkg.all;
use work.apb_pkg.all;

entity tx_chain is
    port (
        clk_64 : in std_logic;
        resetn : in std_logic;
		-- Control Regs
		s_apb_in : in apb_in_t;
        s_apb_out : out apb_out_t;
        -- Modulation source
        source_axis_out_mod : in axis_in_mod_t;
        source_axis_in_mod : out axis_out_mod_t;
		-- TX output
        tx_axis_iq_o : out axis_in_iq_t;
		tx_axis_iq_i : in axis_out_iq_t
    );
end entity tx_chain;

architecture rtl of tx_chain is
	signal resampler_axis_out_mod		: axis_in_mod_t;
	signal resampler_axis_in_mod		: axis_out_mod_t;
	-- FM
    signal fm_mod_axis_in_mod    		: axis_out_mod_t;
	signal freq_mod_axis_in_iq			: axis_in_iq_t;
    signal freq_mod_axis_out_iq			: axis_out_iq_t;
	signal fm_nw                        : std_logic;
	-- AM
	signal am_mod_axis_in_mod    		: axis_out_mod_t;
	signal ampl_mod_axis_in_iq			: axis_in_iq_t;
    signal ampl_mod_axis_out_iq			: axis_out_iq_t;
	-- SSB
	signal fir_axis_in_mod    			: axis_out_mod_t;
	signal fir_axis_in_iq				: axis_in_iq_t;
    signal fir_axis_out_iq				: axis_out_iq_t;
	signal ssb_sideband                 : std_logic;

	-- post-processing
	signal gain_axis_in_mod				: axis_out_mod_t;
	signal gain_axis_out_mod			: axis_in_mod_t;
	signal bal_axis_in_iq				: axis_out_iq_t;
	signal bal_axis_out_iq				: axis_in_iq_t;
	signal offset_axis_in_iq			: axis_out_iq_t;
	signal offset_axis_out_iq			: axis_in_iq_t;

	signal mode : std_logic_vector(2 downto 0);

	signal s_apb_out_tx_regs : apb_out_t;
	signal s_apb_out_iqbal : apb_out_t;
	signal s_apb_out_iqoffs : apb_out_t;

begin
	apb_merge_inst : entity work.apb_merge
	generic map (
	  N_SLAVES => 3
	)
	port map (
	  clk_i => clk_64,
	  rstn_i => resetn,
	  m_apb_in => s_apb_in,
	  m_apb_out => s_apb_out,
	  s_apb_in => open,
	  s_apb_out(0) => s_apb_out_tx_regs,
	  s_apb_out(1) => s_apb_out_iqbal,
	  s_apb_out(2) => s_apb_out_iqoffs
	);

	tx_apb_regs_inst : entity work.tx_apb_regs
	generic map (
		PSEL_ID => 1
	)
	port map (
		clk => clk_64,
		s_apb_in => s_apb_in,
		s_apb_out => s_apb_out_tx_regs,
		mode => mode,
		fm_nw => fm_nw,
		ssb_sideband => ssb_sideband
	);
    -- Interpolator 8 to 400kHz
	interpol0: entity work.mod_resampler
	port map(
		clk_i => clk_64,
		s_axis_mod_i => source_axis_out_mod,
		s_axis_mod_o => source_axis_in_mod,
		m_axis_mod_o => resampler_axis_out_mod,
		m_axis_mod_i => gain_axis_in_mod
	);

	-- Gain block
	post_gain0: entity work.gain_mod port map(
		clk_i => clk_64,
		s_axis_mod_i => resampler_axis_out_mod,
		s_axis_mod_o => gain_axis_in_mod,
		m_axis_mod_o => gain_axis_out_mod,
		m_axis_mod_i => resampler_axis_in_mod
	);

    -- Frequency modulator
    freq_mod0: entity work.fm_modulator
    port map(
        clk_i => clk_64,
        nrst_i => resetn,
        nw_i => fm_nw,
        s_axis_mod_i => gain_axis_out_mod,
        s_axis_mod_o => fm_mod_axis_in_mod,
        m_axis_iq_i => freq_mod_axis_out_iq,
        m_axis_iq_o => freq_mod_axis_in_iq
    );

    -- Amplitude modulator
    ampl_mod0: entity work.am_modulator
    port map(
        clk_i => clk_64,
        s_axis_mod_i => gain_axis_out_mod,
        s_axis_mod_o => am_mod_axis_in_mod,
        m_axis_iq_i => ampl_mod_axis_out_iq,
        m_axis_iq_o => ampl_mod_axis_in_iq
    );

	-- FIR filter (for SSB)
	tx_fir_inst : entity work.tx_fir
	port map (
	  clk_i => clk_64,
	  mode => ssb_sideband,
	  s_axis_mod_i => gain_axis_out_mod,
	  s_axis_mod_o => fir_axis_in_mod,
	  m_axis_iq_i => fir_axis_out_iq,
	  m_axis_iq_o => fir_axis_in_iq
	);

	-- Backpropagation of the ready signal to interpolator
	axis_fork0: entity work.axis_fork port map(
		s_mod_in => resampler_axis_in_mod,
		sel_i => mode,
		m00_mod_out => fm_mod_axis_in_mod,
		m01_mod_out => am_mod_axis_in_mod,
		m02_mod_out => fir_axis_in_mod,
		m03_mod_out => axis_out_mod_null,
		m04_mod_out => axis_out_mod_null
	);

	-- modulation selector
	tx_mod_sel0: entity work.mod_sel port map(
		clk_i => clk_64,
		sel_i => mode,
		s00_axis_iq_i => freq_mod_axis_in_iq, -- FM
		s01_axis_iq_i => ampl_mod_axis_in_iq, -- AM
		s02_axis_iq_i => fir_axis_in_iq, -- SSB
		s03_axis_iq_i => (x"7FFF0000", '1'), -- reserved
		s04_axis_iq_i => (x"7FFF1FF0", '1'), -- reserved
		s00_axis_iq_o => freq_mod_axis_out_iq,
		s01_axis_iq_o => ampl_mod_axis_out_iq,
		s02_axis_iq_o => fir_axis_out_iq,
		s03_axis_iq_o => open,
		s04_axis_iq_o => open,
		m_axis_iq_i => bal_axis_in_iq,
		m_axis_iq_o => bal_axis_out_iq
	);

	-- I/Q balancing block
	iq_balance0: entity work.bal_iq
	generic map (
		PSEL_ID => 2
	)
	port map(
		clk_i		=> clk_64,
		s_apb_in => s_apb_in,
		s_apb_out => s_apb_out_iqbal,
		s_axis_iq_i	=> bal_axis_out_iq,
		s_axis_iq_o	=> bal_axis_in_iq,
		m_axis_iq_o	=> offset_axis_out_iq,
		m_axis_iq_i	=> offset_axis_in_iq
	);

	-- I/Q offset block
	iq_offset0: entity work.offset_iq
	generic map (
		PSEL_ID => 3
	)
	port map(
		clk_i		=> clk_64,
		s_apb_in => s_apb_in,
		s_apb_out => s_apb_out_iqoffs,
		s_axis_iq_i	=> offset_axis_out_iq,
		s_axis_iq_o	=> offset_axis_in_iq,
		m_axis_iq_o	=> tx_axis_iq_o,
		m_axis_iq_i	=> tx_axis_iq_i
	);

end architecture;