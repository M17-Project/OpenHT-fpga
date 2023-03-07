-------------------------------------------------------------
-- Dither adder for NCO's phase accumulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- February 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dither_adder is
    port(
        phase_i	: in unsigned(20 downto 0);
		dith_i	: in signed(15 downto 0);
        phase_o	: out unsigned(20 downto 0) := (others => '0')
    );
end entity;

architecture magic of dither_adder is
	signal sum : signed(21 downto 0) := (others => '0');
	
begin
	sum <= signed("0" & phase_i) + dith_i;
	phase_o <= unsigned(sum(20 downto 0));
end architecture;