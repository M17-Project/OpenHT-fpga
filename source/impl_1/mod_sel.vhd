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
		sel			: in std_logic_vector(1 downto 0);		-- mod selector
		am_i_i		: in std_logic_vector(15 downto 0);		-- FM I data in
		am_q_i		: in std_logic_vector(15 downto 0);		-- FM Q data in
		fm_i_i		: in std_logic_vector(15 downto 0);		-- FM I data in
		fm_q_i		: in std_logic_vector(15 downto 0);		-- FM Q data in
		i_o			: out std_logic_vector(15 downto 0);	-- I data out
		q_o			: out std_logic_vector(15 downto 0)		-- Q data out
	);
end mod_sel;

architecture magic of mod_sel is
begin
	i_o <= am_i_i when sel="01" else
		fm_i_i when sel="10" else
		(others => '0');
	
	q_o <= am_q_i when sel="01" else
		fm_q_i when sel="10" else
		(others => '0');
end magic;