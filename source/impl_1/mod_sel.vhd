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
		m_axis_iq_i : in axis_out_iq_t;
		
		s_mod_in	: out axis_out_mod_t;
        m00_mod_out : in axis_out_mod_t;
        m01_mod_out : in axis_out_mod_t;
        m02_mod_out : in axis_out_mod_t;
        m03_mod_out : in axis_out_mod_t;
        m04_mod_out : in axis_out_mod_t
	);
end mod_sel;

architecture magic of mod_sel is
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
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
	end process;
	
	s_mod_in <= m00_mod_out when sel_i = "000" else 
		m01_mod_out when sel_i = "001" else 
		m02_mod_out when sel_i = "010" else 
		m03_mod_out when sel_i = "011" else
		m04_mod_out when sel_i = "100";

	s00_axis_iq_o.tready <= m_axis_iq_i.tready;
	s01_axis_iq_o.tready <= m_axis_iq_i.tready;
	s02_axis_iq_o.tready <= m_axis_iq_i.tready;
	s03_axis_iq_o.tready <= m_axis_iq_i.tready;
	s04_axis_iq_o.tready <= m_axis_iq_i.tready;
end magic;
