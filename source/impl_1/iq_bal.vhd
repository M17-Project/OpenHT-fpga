-------------------------------------------------------------
-- I/Q balancer block
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

entity bal_iq is
    port (
		clk_i        	: in std_logic;
		i_bal_i			: in std_logic_vector(15 downto 0);
		q_bal_i			: in std_logic_vector(15 downto 0);
		s_axis_iq_i 	: in axis_in_iq_t;
		s_axis_iq_o 	: out axis_out_iq_t;
		m_axis_iq_o 	: out axis_in_iq_t;
		m_axis_iq_i 	: in axis_out_iq_t
    );
end entity bal_iq;

architecture magic of bal_iq is
	signal i_mult, q_mult : std_logic_vector(31 downto 0) := (others => '0');
	signal out_valid : std_logic := '0';
begin
	i_mult <= std_logic_vector(signed(s_axis_iq_i.tdata(31 downto 16)) * signed(i_bal_i));
	q_mult <= std_logic_vector(signed(s_axis_iq_i.tdata(15 downto 0))  * signed(q_bal_i));

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_axis_iq_o.tready then
				m_axis_iq_o.tdata <= i_mult(31-2 downto 16-2) & q_mult(31-2 downto 16-2); -- TODO: add saturation here
				out_valid <= s_axis_iq_i.tvalid;
			end if;
		end if;
	end process;

	m_axis_iq_o.tvalid <= out_valid;
	s_axis_iq_o.tready <= m_axis_iq_i.tready or not out_valid;
end architecture;