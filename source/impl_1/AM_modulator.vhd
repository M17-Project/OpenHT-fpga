-------------------------------------------------------------
-- Complex amplitude modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- Sebastien Van Cauwenberghe, ON4SEB
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;

entity am_modulator is
	port(
		clk_i : in std_logic;
		s_axis_mod_i : in axis_in_mod_t;
		s_axis_mod_o : out axis_out_mod_t;
		m_axis_iq_o : out axis_in_iq_t;
		m_axis_iq_i : in axis_out_iq_t
	);
end am_modulator;

architecture magic of am_modulator is
begin
	process (clk_i)
	begin
		if rising_edge(clk_i) then
			if s_axis_mod_i.tvalid and m_axis_iq_i.tready then
				m_axis_iq_o.tdata(31 downto 16) <= '0' & s_axis_mod_i.tdata(14 downto 1);
				m_axis_iq_o.tdata(15 downto 0) <= (others => '0');
			end if;

			-- push the flags further
			m_axis_iq_o.tlast <= s_axis_mod_i.tlast;
			m_axis_iq_o.tvalid <= s_axis_mod_i.tvalid;
		end if;
	end process;

	-- pass the TREADY flag as is
	s_axis_mod_o.tready <= m_axis_iq_i.tready;
end magic;
