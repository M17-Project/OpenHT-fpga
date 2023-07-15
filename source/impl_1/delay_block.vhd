-------------------------------------------------------------
-- Delay block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity delay_block is
	generic(
		DELAY		: integer := 40
	);
	port(
		clk_i	: in std_logic;									-- fast clock in
		trig_i	: in std_logic;									-- trigger in
		d_i		: in signed(15 downto 0);						-- data in
		d_o		: out signed(15 downto 0) := (others => '0')	-- data out
	);
end delay_block;

architecture magic of delay_block is
	type d_line is array(0 to DELAY-1) of signed(15 downto 0);
	signal dline : d_line := (others => (others => '0'));
	signal p_trig, pp_trig : std_logic := '0';
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;
			
			if pp_trig='0' and p_trig='1' then
				dline <= dline(1 to DELAY-1) & d_i;
			end if;
		end if;
	end process;
	
	d_o <= dline(0);
end magic;
