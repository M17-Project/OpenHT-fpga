-------------------------------------------------------------
-- Complex amplitude modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity am_modulator is
	port(
		mod_i	: in std_logic_vector(15 downto 0);		-- modulation in
		i_o		: out std_logic_vector(15 downto 0);	-- I data out
		q_o		: out std_logic_vector(15 downto 0)		-- Q data out
	);
end am_modulator;

architecture magic of am_modulator is
begin
	i_o <= mod_i;
	q_o <= (others => '0'); --zero
end magic;
