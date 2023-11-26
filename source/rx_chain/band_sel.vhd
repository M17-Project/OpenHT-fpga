-------------------------------------------------------------
-- Band source selector (multiplexer)
--
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- M17 Project
-- November 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.axi_stream_pkg.all;

entity band_sel is
	port(
		clk_i		: in std_logic;		-- clock in
		sel_i		: in std_logic;		-- band selector

		s00_axis_iq_i : in axis_in_iq_t;
		s00_axis_iq_o : out axis_out_iq_t;
		s01_axis_iq_i : in axis_in_iq_t;
		s01_axis_iq_o : out axis_out_iq_t;

		m_axis_iq_o : out axis_in_iq_t;
		m_axis_iq_i : in axis_out_iq_t
	);
end band_sel;

architecture magic of band_sel is
	signal ds_ready : std_logic;
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if ds_ready then
				case sel_i is
					when '0' =>
						m_axis_iq_o	<= s00_axis_iq_i;

					when '1' =>
						m_axis_iq_o	<= s01_axis_iq_i;

					when others =>
						m_axis_iq_o.tvalid <= '0';
				end case;
			end if;
		end if;
	end process;

	ds_ready <= m_axis_iq_i.tready or not m_axis_iq_o.tvalid;

	s00_axis_iq_o.tready <= ds_ready;
	s01_axis_iq_o.tready <= ds_ready;

end magic;
