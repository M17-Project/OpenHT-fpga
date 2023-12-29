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
        source_axis_out : in axis_in_iq_t;
        source_axis_in : out axis_out_iq_t;
		-- TX output
        tx_axis_iq_o : out axis_in_iq_t;
		tx_axis_iq_i : in axis_out_iq_t;
		-- Debug outputs
		dbg0_in : out axis_in_iq_t;
		dbg0_out : out axis_out_iq_t;
		dbg1_in : out axis_in_iq_t;
		dbg1_out : out axis_out_iq_t;
		dbg2_in : out axis_in_iq_t;
		dbg2_out : out axis_out_iq_t;
		dbg3_in : out axis_in_iq_t;
		dbg3_out : out axis_out_iq_t;
		dbg4_in : out axis_in_iq_t;
		dbg4_out : out axis_out_iq_t;
		dbg5_in : out axis_in_iq_t;
		dbg5_out : out axis_out_iq_t;
		dbg6_in : out axis_in_iq_t;
		dbg6_out : out axis_out_iq_t;
		dbg7_in : out axis_in_iq_t;
		dbg7_out : out axis_out_iq_t
    );
end entity tx_chain;

architecture rtl of tx_chain is
	-- Prefilter
	signal prefilter_ctcss_axis_in	: axis_in_iq_t;
	signal prefilter_ctcss_axis_out  : axis_out_iq_t;
	-- CTCSS
	signal ctcss_interp0_axis_in		: axis_in_iq_t;
	signal ctcss_interp0_axis_out    : axis_out_iq_t;
	-- Interpolators
	signal interp0_interp1_axis_in		: axis_in_iq_t;
	signal interp0_interp1_axis_out    : axis_out_iq_t;
	signal interp1_interp2_axis_in		: axis_in_iq_t;
	signal interp1_interp2_axis_out    : axis_out_iq_t;
	signal interp2_mods_axis_in		: axis_in_iq_t;
	signal interp2_mods_axis_out    : axis_out_iq_t;

	-- FM
    signal fm_iq_axis_in    		: axis_out_iq_t;
	signal freq_iq_axis_in			: axis_in_iq_t;
    signal freq_iq_axis_out			: axis_out_iq_t;
	signal fm_nw                        : std_logic;
	-- AM
	signal am_iq_axis_in    		: axis_out_iq_t;
	signal ampl_iq_axis_in			: axis_in_iq_t;
    signal ampl_iq_axis_out			: axis_out_iq_t;
	-- SSB
	signal ssb_sideband             : std_logic;
	signal direct_iq_axis_in        : axis_out_iq_t;

	-- post-processing
	signal bal_axis_in				: axis_out_iq_t;
	signal bal_axis_out				: axis_in_iq_t;
	signal offset_axis_in			: axis_out_iq_t;
	signal offset_axis_out			: axis_in_iq_t;

	signal mode : std_logic_vector(2 downto 0);

	signal s_apb_out_tx_regs : apb_out_t;
	signal s_apb_out_iqbal : apb_out_t;
	signal s_apb_out_iqoffs : apb_out_t;
	signal s_apb_out_prefilter : apb_out_t;
	signal s_apb_out_ctcss : apb_out_t;
	signal s_apb_out_interp0 : apb_out_t;
	signal s_apb_out_interp1 : apb_out_t;
	signal s_apb_out_interp2 : apb_out_t;

begin
	apb_merge_inst : entity work.apb_merge
	generic map (
	  N_SLAVES => 8
	)
	port map (
	  clk_i => clk_64,
	  rstn_i => resetn,
	  m_apb_in => s_apb_in,
	  m_apb_out => s_apb_out,
	  s_apb_in => open,
	  s_apb_out(0) => s_apb_out_tx_regs,
	  s_apb_out(1) => s_apb_out_iqbal,
	  s_apb_out(2) => s_apb_out_iqoffs,
	  s_apb_out(3) => s_apb_out_prefilter,
	  s_apb_out(4) => s_apb_out_ctcss,
	  s_apb_out(5) => s_apb_out_interp0,
	  s_apb_out(6) => s_apb_out_interp1,
	  s_apb_out(7) => s_apb_out_interp2
	);

	tx_apb_regs_inst : entity work.tx_apb_regs
	generic map (
		PSEL_ID => C_TX_REGS_PSEL
	)
	port map (
		clk => clk_64,
		s_apb_in => s_apb_in,
		s_apb_out => s_apb_out_tx_regs,
		mode => mode,
		fm_nw => fm_nw,
		ssb_sideband => ssb_sideband
	);

	dbg0_in <= source_axis_out;
	dbg0_out <= source_axis_in;
	prefilter_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_TX_PREFILTER_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_prefilter,
	  s_axis_i => source_axis_out,
	  s_axis_o => source_axis_in,
	  m_axis_o => prefilter_ctcss_axis_in,
	  m_axis_i => prefilter_ctcss_axis_out
	);
	dbg1_in <= prefilter_ctcss_axis_in;
	dbg1_out <= prefilter_ctcss_axis_out;

	ctcss_gen_inst : entity work.ctcss_gen
  	generic map (
    	PSEL_ID => C_TX_CTCSS_PSEL
  	)
  	port map (
		clk_i => clk_64,
		nrst_i => resetn,
		s_apb_in => s_apb_in,
		s_apb_out => s_apb_out_ctcss,
		s_axis_i => prefilter_ctcss_axis_in,
		s_axis_o => prefilter_ctcss_axis_out,
		m_axis_i => ctcss_interp0_axis_out,
		m_axis_o => ctcss_interp0_axis_in
  	);
	  dbg2_in <= ctcss_interp0_axis_in;
	  dbg2_out <= ctcss_interp0_axis_out;

    -- Interpolator set
	interp0_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_TX_INTERP0_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_interp0,
	  s_axis_i => ctcss_interp0_axis_in,
	  s_axis_o => ctcss_interp0_axis_out,
	  m_axis_o => interp0_interp1_axis_in,
	  m_axis_i => interp0_interp1_axis_out
	);
	dbg3_in <= interp0_interp1_axis_in;
	dbg3_out <= interp0_interp1_axis_out;

	interp1_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_TX_INTERP1_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_interp1,
	  s_axis_i => interp0_interp1_axis_in,
	  s_axis_o => interp0_interp1_axis_out,
	  m_axis_o => interp1_interp2_axis_in,
	  m_axis_i => interp1_interp2_axis_out
	);
	dbg4_in <= interp1_interp2_axis_in;
	dbg4_out <= interp1_interp2_axis_out;

	interp2_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_TX_INTERP2_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_interp2,
	  s_axis_i => interp1_interp2_axis_in,
	  s_axis_o => interp1_interp2_axis_out,
	  m_axis_o => interp2_mods_axis_in,
	  m_axis_i => interp2_mods_axis_out
	);
	dbg5_in <= interp2_mods_axis_in;
	dbg5_out <= interp2_mods_axis_out;

    -- Frequency modulator
    freq_mod0: entity work.fm_modulator
    port map(
        clk_i => clk_64,
        nrst_i => resetn,
        nw_i => fm_nw,
        s_axis_iq_i => interp2_mods_axis_in,
        s_axis_iq_o => fm_iq_axis_in,
        m_axis_iq_i => freq_iq_axis_out,
        m_axis_iq_o => freq_iq_axis_in
    );

    -- Amplitude modulator
    ampl_mod0: entity work.am_modulator
    port map(
        clk_i => clk_64,
        s_axis_i => interp2_mods_axis_in,
        s_axis_o => am_iq_axis_in,
        m_axis_i => ampl_iq_axis_out,
        m_axis_o => ampl_iq_axis_in
    );

	-- Backpropagation of the ready signal to interpolator
	axis_fork0: entity work.axis_fork port map(
		s_iq_in => interp2_mods_axis_out,
		sel_i => mode,
		m00_iq_out => fm_iq_axis_in,
		m01_iq_out => am_iq_axis_in,
		m02_iq_out => direct_iq_axis_in,
		m03_iq_out => axis_out_iq_null,
		m04_iq_out => axis_out_iq_null
	);

	-- modulation selector
	tx_iq_sel0: entity work.mod_sel port map(
		clk_i => clk_64,
		sel_i => mode,
		s00_axis_iq_i => freq_iq_axis_in, -- FM
		s01_axis_iq_i => ampl_iq_axis_in, -- AM
		s02_axis_iq_i => interp2_mods_axis_in, -- SSB/PM, direct IQ modulation
		s03_axis_iq_i => (x"7FFF0000", x"F", '1'), -- reserved
		s04_axis_iq_i => (x"7FFF1FF0", x"F", '1'), -- reserved
		s00_axis_iq_o => freq_iq_axis_out,
		s01_axis_iq_o => ampl_iq_axis_out,
		s02_axis_iq_o => direct_iq_axis_in,
		s03_axis_iq_o => open,
		s04_axis_iq_o => open,
		m_axis_iq_i => bal_axis_in,
		m_axis_iq_o => bal_axis_out
	);
	dbg6_in <= bal_axis_out;
	dbg6_out <= bal_axis_in;

	-- I/Q balancing block
	iq_balance0: entity work.bal_iq
	generic map (
		PSEL_ID => C_TX_IQ_GAIN_PSEL
	)
	port map(
		clk_i		=> clk_64,
		s_apb_in => s_apb_in,
		s_apb_out => s_apb_out_iqbal,
		s_axis_iq_i	=> bal_axis_out,
		s_axis_iq_o	=> bal_axis_in,
		m_axis_iq_o	=> offset_axis_out,
		m_axis_iq_i	=> offset_axis_in
	);
	dbg7_in <= offset_axis_out;
	dbg7_out <= offset_axis_in;

	-- I/Q offset block
	iq_offset0: entity work.offset_iq
	generic map (
		PSEL_ID => C_TX_IQ_OFFSET_PSEL
	)
	port map(
		clk_i		=> clk_64,
		s_apb_in => s_apb_in,
		s_apb_out => s_apb_out_iqoffs,
		s_axis_iq_i	=> offset_axis_out,
		s_axis_iq_o	=> offset_axis_in,
		m_axis_iq_o	=> tx_axis_iq_o,
		m_axis_iq_i	=> tx_axis_iq_i
	);

end architecture;