-------------------------------------------------------------
-- OpenHT's RX toplevel
--
-- Sebastien Van Cauwenberghe, ON4SEB
-- M17 Project
-- Novembre 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;
use work.apb_pkg.all;

entity rx_chain is
    port (
        clk_64 : in std_logic;
        resetn : in std_logic;
        -- Control Regs
		s_apb_in : in apb_in_t;
        s_apb_out : out apb_out_t;
        -- RX data 09/24
		band_i : in std_logic;
		rx_mod09_iq_i : in axis_in_iq_t;
		rx_mod09_iq_o : out axis_out_iq_t;
		rx_mod24_iq_i : in axis_in_iq_t;
		rx_mod24_iq_o : out axis_out_iq_t;
		-- Demod data
        rx_demod_iq_out : out axis_in_iq_t;
		rx_demod_iq_in : in axis_out_iq_t
    );
end entity rx_chain;

architecture rtl of rx_chain is
    -- APB
	signal s_apb_out_dec0 : apb_out_t;
	signal s_apb_out_dec1 : apb_out_t;
	signal s_apb_out_dec2 : apb_out_t;
	signal s_apb_out_demod : apb_out_t;
    signal s_apb_out_postfilter : apb_out_t;
	signal s_apb_out_rssi : apb_out_t;

    -- AXI streams
    signal sel_dec0_axis_in  : axis_in_iq_t;
	signal sel_dec0_axis_out : axis_out_iq_t;

    signal dec0_dec1_axis_in  : axis_in_iq_t;
	signal dec0_dec1_axis_out : axis_out_iq_t;

	signal dec1_dec2_axis_in  : axis_in_iq_t;
	signal dec1_dec2_axis_out : axis_out_iq_t;

    signal dec2_demod_axis_in  : axis_in_iq_t;
	signal dec2_demod_axis_out : axis_out_iq_t;

    signal demod_postfilter_axis_in  : axis_in_iq_t;
	signal demod_postfilter_axis_out : axis_out_iq_t;

begin
    -- Configuration registers
    apb_merge_inst : entity work.apb_merge
	generic map (
	  N_SLAVES => 4
	)
	port map (
	  clk_i => clk_64,
	  rstn_i => resetn,
	  m_apb_in => s_apb_in,
	  m_apb_out => s_apb_out,
	  s_apb_in => open,
	  s_apb_out(0) => s_apb_out_dec0,
	  s_apb_out(1) => s_apb_out_dec1,
	  s_apb_out(2) => s_apb_out_dec2,
	  s_apb_out(3) => s_apb_out_postfilter
	);

	-- Select 400/2400 Band
	band_sel_inst : entity work.band_sel
	port map (
	  clk_i => clk_64,
	  sel_i => band_i,
	  s00_axis_iq_i => rx_mod09_iq_i,
	  s00_axis_iq_o => rx_mod09_iq_o,
	  s01_axis_iq_i => rx_mod24_iq_i,
	  s01_axis_iq_o => rx_mod24_iq_o,
	  m_axis_iq_o => sel_dec0_axis_in,
	  m_axis_iq_i => sel_dec0_axis_out
	);

    -- Decimators
	dec0_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_RX_DEC0_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_dec0,
	  s_axis_i => sel_dec0_axis_in,
	  s_axis_o => sel_dec0_axis_out,
	  m_axis_o => dec0_dec1_axis_in,
	  m_axis_i => dec0_dec1_axis_out
	);

	dec1_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_RX_DEC1_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_dec1,
	  s_axis_i => dec0_dec1_axis_in,
	  s_axis_o => dec0_dec1_axis_out,
	  m_axis_o => dec1_dec2_axis_in,
	  m_axis_i => dec1_dec2_axis_out
	);

	dec2_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_RX_DEC2_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_dec2,
	  s_axis_i => dec1_dec2_axis_in,
	  s_axis_o => dec1_dec2_axis_out,
	  m_axis_o => dec2_demod_axis_in,
	  m_axis_i => dec2_demod_axis_out
	);

	-- RSSI estimator
	RSSI_estimator_inst : entity work.RSSI_estimator
	generic map (
	  PSEL_ID => C_RX_RSSI_PSEL
	)
	port map (
	  clk_i => clk_64,
	  nrst_i => resetn,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_rssi,
	  s_axis_o => dec2_demod_axis_out,
	  s_axis_i => dec2_demod_axis_in
	);

    -- Demodulator
	APFM_demodulator_inst : entity work.APFM_demodulator
	generic map (
		PSEL_ID => C_RX_DEMOD_PSEL
	)
	port map (
		clk_i => clk_64,
		nrst_i => resetn,
		s_apb_i => s_apb_in,
		s_apb_o => s_apb_out_demod,
		s_axis_o => dec2_demod_axis_out,
		s_axis_i => dec2_demod_axis_in,
		m_axis_o => demod_postfilter_axis_in,
		m_axis_i => demod_postfilter_axis_out
	);

    -- Postfilter
	postfilter_inst : entity work.fir_rational_resample
	generic map (
	  PSEL_ID => C_RX_POSTFILTER_PSEL
	)
	port map (
	  clk_i => clk_64,
	  s_apb_i => s_apb_in,
	  s_apb_o => s_apb_out_postfilter,
	  s_axis_i => demod_postfilter_axis_in,
	  s_axis_o => demod_postfilter_axis_out,
	  m_axis_o => rx_demod_iq_out,
	  m_axis_i => rx_demod_iq_in
	);

end architecture;