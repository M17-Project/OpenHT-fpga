library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;

entity axis_fork is
    port (
        s_mod_in : out axis_out_mod_t;
		sel_i		: in std_logic_vector(2 downto 0);		-- mod selector
        m00_mod_out : in axis_out_mod_t;
        m01_mod_out : in axis_out_mod_t;
        m02_mod_out : in axis_out_mod_t;
        m03_mod_out : in axis_out_mod_t;
        m04_mod_out : in axis_out_mod_t
    );
end entity axis_fork;

architecture rtl of axis_fork is

begin
    --s_mod_in.tready <= m00_mod_out.tready or
        --m01_mod_out.tready or
        --m02_mod_out.tready or
        --m03_mod_out.tready or
        --m04_mod_out.tready;
		
	s_mod_in.tready <= m00_mod_out.tready when sel_i = "000" else 
		m01_mod_out.tready when sel_i = "001" else 
		m02_mod_out.tready when sel_i = "010" else 
		m03_mod_out.tready when sel_i = "011" else
		m04_mod_out.tready when sel_i = "100" else
		'0';
end architecture;