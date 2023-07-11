-------------------------------------------------------------
-- Complex amplitude modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity am_modulator is
	port(
		clk_i	: in std_logic;											-- clock in
		mod_i	: in std_logic_vector(15 downto 0);						-- modulation in
		i_o		: out std_logic_vector(15 downto 0) := (others => '0');	-- I data out
		q_o		: out std_logic_vector(15 downto 0) := (others => '0')	-- Q data out
	);
end am_modulator;

architecture magic of am_modulator is
begin
	--process(clk_i)
	--begin
		--if rising_edge(clk_i) then
			i_o <= '0' & mod_i(15 downto 1);
			q_o <= (others => '0'); --zero
		--end if;
	--end process;
end magic;
