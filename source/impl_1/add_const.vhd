-------------------------------------------------------------
-- Simple add constant block
--
-- Converts signed to std_logic_vector
-- by adding half-range value
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity add_const is
	generic(
		CONST_VAL : integer := 16#7FFF#
	);
	port(
		data_i		: in signed(15 downto 0);								-- data in
		data_o		: out std_logic_vector(15 downto 0) := (others => '0')	-- data out
	);
end add_const;

architecture magic of add_const is
	--
begin
	data_o <= std_logic_vector(data_i + CONST_VAL);
end magic;
