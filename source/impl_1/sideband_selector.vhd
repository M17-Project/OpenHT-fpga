-------------------------------------------------------------
-- Sideband selector
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sideband_sel is
	port(
		sel			: in std_logic;									-- sideband selector (0-USB, 1-LSB)
		d_i			: in signed(15 downto 0);						-- data in
		d_o			: out signed(15 downto 0) := (others => '0')	-- data out
	);
end sideband_sel;

architecture magic of sideband_sel is
begin
	d_o <= d_i when sel='1' else -d_i;
end magic;
