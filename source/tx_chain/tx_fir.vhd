-------------------------------------------------------------
-- TX FIR Filter
--
-- Sebastien, ON4SEB
-- M17 Project
-- Sept 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.axi_stream_pkg.all;
use work.openht_utils_pkg.all;

entity tx_fir is
	port(
		clk_i        : in std_logic;
		mode         : in std_logic;
		s_axis_mod_i : in axis_in_mod_t;
		s_axis_mod_o : out axis_out_mod_t;
		m_axis_iq_o : out axis_in_iq_t;
		m_axis_iq_i : in axis_out_iq_t
	);
end tx_fir;

architecture magic of tx_fir is
	constant C_TAPS_I : taps_mod_t := (
		x"0000", x"ffff", x"fffe", x"fffc", x"fff8", x"fff4", x"ffef", x"ffe9",
		x"ffe3", x"ffdf", x"ffdc", x"ffde", x"ffe6", x"fff5", x"000c", x"002d"
	);

	constant C_TAPS_Q : taps_mod_t := (
		x"0000", x"ffff", x"fffe", x"fffc", x"fff8", x"fff4", x"ffef", x"ffe9",
		x"ffe3", x"ffdf", x"ffdc", x"ffde", x"ffe6", x"fff5", x"000c", x"002d"
	);

	signal axis_in	    	: axis_out_mod_t;
	signal i_axis_out		: axis_in_mod_t;
	signal q_axis_out		: axis_in_mod_t;
begin
	fir_i: entity work.fir_rational_resample
	generic map(
		N_TAPS	=> 16,
		L		=> 1,
		M       => 1,
		C_TAPS	=> C_TAPS_I,
		C_OUT_SHIFT => 0
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> s_axis_mod_i,
		s_axis_mod_o	=> s_axis_mod_o,
		m_axis_mod_o	=> i_axis_out,
		m_axis_mod_i 	=> axis_in
	);

	fir_q: entity work.fir_rational_resample
	generic map(
		N_TAPS	=> 16,
		L		=> 1,
		M       => 1,
		C_TAPS	=> C_TAPS_Q,
		C_OUT_SHIFT => 0
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> s_axis_mod_i,
		s_axis_mod_o	=> open,
		m_axis_mod_o	=> q_axis_out,
		m_axis_mod_i 	=> axis_in
	);

	m_axis_iq_o.tdata(31 downto 16) <= i_axis_out.tdata;
	m_axis_iq_o.tdata(15 downto 0) <= q_axis_out.tdata when mode = '0' else std_logic_vector(-(signed(q_axis_out.tdata)));
	m_axis_iq_o.tvalid <= i_axis_out.tvalid;
	axis_in.tready <= m_axis_iq_i.tready;

end magic;
