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
use work.apb_pkg.all;

entity offset_iq is
	generic (
		PSEL_ID : natural
	);
    port (
		clk_i        	: in std_logic;
		s_apb_in    : in apb_in_t;
		s_apb_out   : out apb_out_t;
		s_axis_iq_i 	: in axis_in_iq_t;
		s_axis_iq_o 	: out axis_out_iq_t;
		m_axis_iq_o 	: out axis_in_iq_t;
		m_axis_iq_i 	: in axis_out_iq_t
    );
end entity offset_iq;

architecture magic of offset_iq is
	signal out_valid : std_logic := '0';

	signal i_offs : std_logic_vector(15 downto 0) := X"0000";
	signal q_offs : std_logic_vector(15 downto 0) := X"0000";
begin
	-- AXI Stream
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_axis_iq_o.tready then
				m_axis_iq_o.tdata <= std_logic_vector(signed(s_axis_iq_i.tdata(31 downto 16))+signed(i_offs))
					& std_logic_vector(signed(s_axis_iq_i.tdata(15 downto 0))+signed(q_offs)); -- TODO: add saturation here
				out_valid <= s_axis_iq_i.tvalid;
				m_axis_iq_o.tstrb <= X"F";
			end if;
		end if;
	end process;

	m_axis_iq_o.tvalid <= out_valid;
	s_axis_iq_o.tready <= m_axis_iq_i.tready or not out_valid;

	-- APB
	process (clk_i)
	begin
		if rising_edge(clk_i) then
			s_apb_out.pready <= '0';
			s_apb_out.prdata <= (others => '0');

			if s_apb_in.PSEL(PSEL_ID) then
				if s_apb_in.PENABLE and s_apb_in.PWRITE then
					case s_apb_in.paddr(1) is
						when '0' => -- I
							i_offs <= s_apb_in.pwdata;

						when '1' => -- Q
							q_offs <= s_apb_in.pwdata;

						when others =>
							null;
					end case;
				end if;

				if not s_apb_in.PENABLE then
					s_apb_out.pready <= '1';
					  case s_apb_in.paddr(1) is
						  when '0' => -- I
							  s_apb_out.prdata <= i_offs;

						  when '1' => -- Q
							  s_apb_out.prdata <= q_offs;

						  when others =>
							  null;
					  end case;
				end if;
			end if;

		end if;
	end process;
end architecture;