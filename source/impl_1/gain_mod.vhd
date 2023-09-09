-------------------------------------------------------------
-- Gain block
--
-- Wojciech Kaczmarski, SP5WWP
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- M17 Project
-- August 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;

entity gain_mod is
    port (
		clk_i        	: in std_logic;
		s_axis_mod_i 	: in axis_in_mod_t;
		s_axis_mod_o 	: out axis_out_mod_t;
		m_axis_mod_o 	: out axis_in_mod_t;
		m_axis_mod_i 	: in axis_out_mod_t
    );
end entity gain_mod;

architecture magic of gain_mod is
	signal gain_out : std_logic_vector(31 downto 0) := (others => '0');
	signal out_valid : std_logic := '0';
begin
	gain_out <= std_logic_vector(signed(s_axis_mod_i.tdata) * x"6AAA"); -- gain = +1.6667

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_axis_mod_o.tready then
				m_axis_mod_o.tdata <= gain_out(31-2 downto 16-2); -- TODO: add saturation here
				out_valid <= s_axis_mod_i.tvalid;
			end if;
		end if;
	end process;

	m_axis_mod_o.tvalid <= out_valid;
	s_axis_mod_o.tready <= m_axis_mod_i.tready or not out_valid;
end architecture;