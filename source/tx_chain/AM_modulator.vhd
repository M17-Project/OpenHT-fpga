-------------------------------------------------------------
-- Complex amplitude modulator
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

entity am_modulator is
	port(
		clk_i : in std_logic;
		s_axis_mod_i : in axis_in_iq_t;
		s_axis_mod_o : out axis_out_iq_t;
		m_axis_iq_o : out axis_in_iq_t;
		m_axis_iq_i : in axis_out_iq_t
	);
end am_modulator;

architecture magic of am_modulator is
	signal post_offset : std_logic_vector(15 downto 0) := (others => '0');
	signal out_valid : std_logic := '0';
begin
	-- Only use I input regardless of Q component
	post_offset <= std_logic_vector(signed(s_axis_mod_i.tdata(31 downto 16)) - 16#8000#);

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_axis_mod_o.tready then
				m_axis_iq_o.tstrb <= X"F"; -- I and Q are valid but only I input is used
				m_axis_iq_o.tdata(31 downto 16) <= '0' & post_offset(15 downto 1);
				m_axis_iq_o.tdata(15 downto 0) <= (others => '0');
				out_valid <= s_axis_mod_i.tvalid;
			end if;

		end if;
	end process;

	m_axis_iq_o.tvalid <= out_valid;
	s_axis_mod_o.tready <= m_axis_iq_i.tready or not out_valid;
end magic;
