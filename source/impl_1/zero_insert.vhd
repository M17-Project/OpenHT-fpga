--zero insert block
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity zero_insert is
	port(
		clk_i	: in std_logic; -- 64MHz clock in
		rst_i	: in std_logic;	-- reset in (output zero words when '1')
		s_o 	: out std_logic -- zero word out ('1' = send zero words)
	);
end zero_insert;

architecture magic of zero_insert is
begin
	-- the sample rate is set to 400k, so 9 out of 10 samples
	-- has to be 'zero words'
	process(clk_i)
		variable counter : integer range 0 to 10*32 := 0;
	begin
		if rising_edge(clk_i) then
			if counter=10*32-1 then
				counter := 0;
			else
				if counter<16 then
					s_o <= '0' or rst_i;
				else
					s_o <= '1';
				end if;
				counter := counter + 1;
			end if;
		end if;
	end process;
end magic;