-------------------------------------------------------------
-- Modulation source selector (multiplexer)
--
-- Wojciech Kaczmarski, SP5WWP
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- M17 Project
-- September 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.axi_stream_pkg.all;

entity mod_sel is
	port(
		clk_i		: in std_logic;							-- clock in
		sel_i		: in std_logic_vector(2 downto 0);		-- mod selector

		s00_axis_iq_i : in axis_in_iq_t;
		s00_axis_iq_o : out axis_out_iq_t;
		s01_axis_iq_i : in axis_in_iq_t;
		s01_axis_iq_o : out axis_out_iq_t;
		s02_axis_iq_i : in axis_in_iq_t;
		s02_axis_iq_o : out axis_out_iq_t;
		s03_axis_iq_i : in axis_in_iq_t;
		s03_axis_iq_o : out axis_out_iq_t;
		s04_axis_iq_i : in axis_in_iq_t;
		s04_axis_iq_o : out axis_out_iq_t;
		
		m_axis_iq_o : out axis_in_iq_t;
		m_axis_iq_i : in axis_out_iq_t
	);
end mod_sel;

architecture magic of mod_sel is
	signal ds_ready : std_logic;
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if ds_ready then
				case sel_i is
					when "000" =>
						m_axis_iq_o	<= s00_axis_iq_i;

					when "001" =>
						m_axis_iq_o	<= s01_axis_iq_i;

					when "010" =>
						m_axis_iq_o	<= s02_axis_iq_i;

					when "011" =>
						m_axis_iq_o	<= s03_axis_iq_i;

					when "100" =>
						m_axis_iq_o	<= s04_axis_iq_i;

					when others =>
						m_axis_iq_o.tvalid <= '0';		
				end case;
			end if;
		end if;
	end process;

	ds_ready <= m_axis_iq_i.tready or not m_axis_iq_o.tvalid;

	s00_axis_iq_o.tready <= ds_ready;
	s01_axis_iq_o.tready <= ds_ready;
	s02_axis_iq_o.tready <= ds_ready;
	s03_axis_iq_o.tready <= ds_ready;
	s04_axis_iq_o.tready <= ds_ready;
end magic;
