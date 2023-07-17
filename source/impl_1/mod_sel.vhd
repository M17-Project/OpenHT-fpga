-------------------------------------------------------------
-- Modulation source selector (multiplexer)
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;

entity mod_sel is
	port(
		clk_i		: in std_logic;							-- clock in
		sel_i		: in std_logic_vector(2 downto 0);		-- mod selector
		m_axis_iq0_i : in axis_in_iq_t;
		m_axis_iq1_i : in axis_in_iq_t;
		m_axis_iq2_i : in axis_in_iq_t;
		m_axis_iq3_i : in axis_in_iq_t;
		m_axis_iq4_i : in axis_in_iq_t;
		m_axis_iq_o : out axis_in_iq_t
	);
end mod_sel;

architecture magic of mod_sel is
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			case sel_i is
				when "000" =>
					m_axis_iq_o <= m_axis_iq0_i;
				when "001" =>
					m_axis_iq_o <= m_axis_iq1_i;
				when "010" =>
					m_axis_iq_o <= m_axis_iq2_i;
				when "011" =>
					m_axis_iq_o <= m_axis_iq3_i;
				when "100" =>
					m_axis_iq_o <= m_axis_iq4_i;
				when others =>
					m_axis_iq_o <= axis_in_iq_null; -- zet to zero if invalid
			end case;
		end if;
	end process;
end magic;