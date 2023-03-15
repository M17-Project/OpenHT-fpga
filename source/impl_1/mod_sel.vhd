-------------------------------------------------------------
-- Modulation source selector (multiplexer)
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mod_sel is
	port(
		sel			: in std_logic_vector(2 downto 0);		-- mod selector
		i0_i, q0_i	: in std_logic_vector(15 downto 0);		-- input 0
		i1_i, q1_i	: in std_logic_vector(15 downto 0);		-- input 1
		i2_i, q2_i	: in std_logic_vector(15 downto 0);		-- input 2
		i3_i, q3_i	: in std_logic_vector(15 downto 0);		-- input 3
		i4_i, q4_i	: in std_logic_vector(15 downto 0);		-- input 4
		i_o			: out std_logic_vector(15 downto 0);	-- I data out
		q_o			: out std_logic_vector(15 downto 0)		-- Q data out
	);
end mod_sel;

architecture magic of mod_sel is
begin
	process(sel)
	begin
		case sel is
			when "000" =>
				i_o <= i0_i;
				q_o <= q0_i;
			when "001" =>
				i_o <= i1_i;
				q_o <= q1_i;
			when "010" =>
				i_o <= i2_i;
				q_o <= q2_i;
			when "011" =>
				i_o <= i3_i;
				q_o <= q3_i;
			when "100" =>
				i_o <= i4_i;
				q_o <= q4_i;
				
			when others =>
				i_o <= (others => '0'); -- zet to zero if invalid
				q_o <= (others => '0');
		end case;
	end process;
end magic;