-------------------------------------------------------------
-- I/Q offset block
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

entity offset_iq is
    port (
		clk_i        	: in std_logic;
		i_offs_i		: in std_logic_vector(15 downto 0);
		q_offs_i		: in std_logic_vector(15 downto 0);
		s_axis_iq_i 	: in axis_in_iq_t;
		s_axis_iq_o 	: out axis_out_iq_t;
		m_axis_iq_o 	: out axis_in_iq_t;
		m_axis_iq_i 	: in axis_out_iq_t
    );
end entity offset_iq;

architecture magic of offset_iq is
	signal out_valid : std_logic := '0';
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_axis_iq_o.tready then
				m_axis_iq_o.tdata <= std_logic_vector(signed(s_axis_iq_i.tdata(31 downto 16))+signed(i_offs_i))
					& std_logic_vector(signed(s_axis_iq_i.tdata(15 downto 0))+signed(q_offs_i)); -- TODO: add saturation here
				out_valid <= s_axis_iq_i.tvalid;
			end if;
		end if;
	end process;

	m_axis_iq_o.tvalid <= out_valid;
	s_axis_iq_o.tready <= m_axis_iq_i.tready or not out_valid;
end architecture;