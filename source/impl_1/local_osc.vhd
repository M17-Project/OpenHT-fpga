-------------------------------------------------------------
-- Local oscillator (complex)
--
-- Frequency = f_trig/DIV
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity local_osc is
	generic(
		DIV		: natural := 10
	);
	port(
		clk_i	: in std_logic;
		trig_i	: in std_logic;
		i_o		: out signed(15 downto 0) := x"7FFF";
		q_o		: out signed(15 downto 0) := x"0000"
	);
end local_osc;

architecture magic of local_osc is
	type lut is array(integer range 0 to DIV-1) of signed(15 downto 0);
	signal i_lut, q_lut : lut;
	signal p_trig, pp_trig : std_logic := '0';
begin
    generate_lut: for n in 0 to DIV-1 generate
        i_lut(n) <= to_signed(integer(real(2**(16-1)-1)*cos(real(n)/real(DIV)*real(2)*real(MATH_PI))), 16);
		q_lut(n) <= to_signed(integer(real(2**(16-1)-1)*sin(real(n)/real(DIV)*real(2)*real(MATH_PI))), 16);
	end generate generate_lut;

	process(clk_i)
		variable cnt : integer range 0 to DIV := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;
		
			if pp_trig='0' and p_trig='1' then
				if cnt=DIV-1 then
					cnt := 0;
				else
					cnt := cnt + 1;
				end if;

				i_o <= i_lut(cnt);
				q_o <= q_lut(cnt);
			end if;
		end if;
	end process;
end magic;
