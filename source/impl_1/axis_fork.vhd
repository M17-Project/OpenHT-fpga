library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;

entity axis_fork is
    port (
        s_mod_in : out axis_out_mod_t;
        m00_mod_out : in axis_out_mod_t;
        m01_mod_out : in axis_out_mod_t;
        m02_mod_out : in axis_out_mod_t;
        m03_mod_out : in axis_out_mod_t;
        m04_mod_out : in axis_out_mod_t
    );
end entity axis_fork;

architecture rtl of axis_fork is

begin
    s_mod_in.tready <= m00_mod_out.tready or
        m01_mod_out.tready or
        m02_mod_out.tready or
        m03_mod_out.tready or
        m04_mod_out.tready;
end architecture;