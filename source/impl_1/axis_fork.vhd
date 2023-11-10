library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;

entity axis_fork is
    port (
        s_iq_in : out axis_out_iq_t;
		sel_i		: in std_logic_vector(2 downto 0);		-- mod selector
        m00_iq_out : in axis_out_iq_t;
        m01_iq_out : in axis_out_iq_t;
        m02_iq_out : in axis_out_iq_t;
        m03_iq_out : in axis_out_iq_t;
        m04_iq_out : in axis_out_iq_t
    );
end entity axis_fork;

architecture rtl of axis_fork is

begin
    --s_iq_in.tready <= m00_iq_out.tready or
        --m01_iq_out.tready or
        --m02_iq_out.tready or
        --m03_iq_out.tready or
        --m04_iq_out.tready;

	s_iq_in.tready <= m00_iq_out.tready when sel_i = "000" else
		m01_iq_out.tready when sel_i = "001" else
		m02_iq_out.tready when sel_i = "010" else
		m03_iq_out.tready when sel_i = "011" else
		m04_iq_out.tready when sel_i = "100" else
		'0';
end architecture;