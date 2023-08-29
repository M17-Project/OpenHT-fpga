-------------------------------------------------------------
-- OpenHT's TX toplevel
--
-- Sebastien Van Cauwenberghe, ON4SEB
-- M17 Project
-- August 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;
use work.regs_pkg.all;

entity tx_chain is
    port (
        clk_64 : in std_logic;
        resetn : in std_logic;
        -- Modulation source
        source_axis_out_mod : in axis_in_mod_t;
        source_axis_in_mod : out axis_out_mod_t;
		-- TX output
        tx_axis_iq_o : out axis_in_iq_t;
		tx_axis_iq_i : in axis_out_iq_t;
        -- TODO remove this
        regs_rw : in rw_regs_t
    );
end entity tx_chain;

architecture rtl of tx_chain is
	signal resampler_axis_out_mod		: axis_in_mod_t;
	signal resampler_axis_in_mod		: axis_out_mod_t;
    signal fm_mod_axis_in_mod    		: axis_out_mod_t;
    signal fm_mod_axis_out_mod    		: axis_out_mod_t;
	signal freq_mod_axis_in_iq			: axis_in_iq_t;
    signal freq_mod_axis_out_iq			: axis_out_iq_t;
	signal gain_axis_in_mod				: axis_out_mod_t;
	signal gain_axis_out_mod			: axis_in_mod_t;
begin
    -- Interpolator 8 to 400kHz
	interpol0: entity work.mod_resampler
	port map(
		clk_i => clk_64,
		s_axis_mod_i => source_axis_out_mod,
		s_axis_mod_o => source_axis_in_mod,
		m_axis_mod_o => resampler_axis_out_mod,
		m_axis_mod_i => gain_axis_in_mod
	);
	
	--gain block
	post_gain0: entity work.gain_mod port map(
		clk_i => clk_64,
		s_axis_mod_i => resampler_axis_out_mod,
		s_axis_mod_o => gain_axis_in_mod,
		m_axis_mod_o => gain_axis_out_mod,
		m_axis_mod_i => resampler_axis_in_mod
	);

    -- Backpropagation of the ready signal to interpolator
    axis_fork_inst : entity work.axis_fork
	port map (
	  s_mod_in => resampler_axis_in_mod,
	  m00_mod_out => fm_mod_axis_in_mod,
	  m01_mod_out => axis_out_mod_null,
	  m02_mod_out => axis_out_mod_null,
	  m03_mod_out => axis_out_mod_null,
	  m04_mod_out => axis_out_mod_null
	);

    -- frequency modulator
    freq_mod0: entity work.fm_modulator
    port map(
        clk_i => clk_64,
        nrst_i => resetn,
        nw_i => regs_rw(CR_2)(8),
        s_axis_mod_i => gain_axis_out_mod,
        s_axis_mod_o => fm_mod_axis_in_mod,
        m_axis_iq_i => freq_mod_axis_out_iq,
        m_axis_iq_o => freq_mod_axis_in_iq
    );
	
    -- amplitude modulator
    ampl_mod0: entity work.am_modulator
    port map(
        clk_i => clk_64,
        s_axis_mod_i => open,
        s_axis_mod_o => open,
        m_axis_iq_i => open,
        m_axis_iq_o => open
    );	

	-- modulation selector
	tx_mod_sel0: entity work.mod_sel port map(
		clk_i => clk_64,
		sel_i => regs_rw(CR_1)(14 downto 12),
		s00_axis_iq_i => freq_mod_axis_in_iq, -- FM
		s01_axis_iq_i => (x"0FFF0000", '1'), -- AM
		s02_axis_iq_i => (x"01FF0000", '1'), -- SSB
		s03_axis_iq_i => (x"7FFF0000", '1'), -- reserved
		s04_axis_iq_i => (x"7FFF1FF0", '1'), -- reserved
		s00_axis_iq_o => freq_mod_axis_out_iq,
		s01_axis_iq_o => open,
		s02_axis_iq_o => open,
		s03_axis_iq_o => open,
		s04_axis_iq_o => open,
		m_axis_iq_i => tx_axis_iq_i,
		m_axis_iq_o => tx_axis_iq_o
	);

end architecture;