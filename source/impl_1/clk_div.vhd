-------------------------------------------------------------
-- Clock frequency division block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clk_div_block is
	generic(
		DIV		: integer := 10
	);
	port(
		clk_i	: in std_logic;			-- fast clock in
		clk_o	: out std_logic := '0'	-- slow clock out
	);
end clk_div_block;

architecture magic of clk_div_block is
	--
begin
	process(clk_i)
		variable cnt : integer := 0;
	begin
		if rising_edge(clk_i) then
			if cnt=DIV-1 then
				cnt := 0;
			else
				cnt := cnt + 1;
			end if;
			
			if cnt<DIV/2 then
				clk_o <= '0';
			else
				clk_o <= '1';
			end if;
		end if;
	end process;
end magic;
