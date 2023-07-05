-------------------------------------------------------------
-- Complex multiply block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity complex_mul is
	port(
		clk_i					: in std_logic;
		a_re, a_im, b_re, b_im	: in signed(15 downto 0);
		c_re, c_im				: out signed(15 downto 0) := (others => '0')
	);
end complex_mul;

architecture magic of complex_mul is
	signal c_re_raw, c_im_raw : signed(31+1 downto 0) := (others => '0');
	signal A, B, C, D : signed(31 downto 0) := (others => '0');
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			c_re <= c_re_raw(32 downto 17);
			c_im <= c_im_raw(32 downto 17);
		end if;
	end process;
	
	-- (a+bi)*(c+di) = (ac-bd)+(ad+bc)i = (A-B)+(C+D)i
	A <= a_re*b_re;
	B <= a_im*b_im;
	C <= a_re*b_im;
	D <= a_im*b_re;

	c_re_raw <= signed(A(31)&A) - signed(B(31)&B);
	c_im_raw <= signed(C(31)&C) + signed(D(31)&D);
end magic;
