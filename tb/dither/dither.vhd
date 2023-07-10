-------------------------------------------------------------
-- Dither source for an NCO in FM mode
--
-- x[0] = seed
-- x[n+1] = (m * x[n] + 7) mod 0xFFFF
--
-- This approach ensures flat probability density
-- of the generated numbers sequence
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dither_source is
    port(
        clk_i	: in  std_logic;
		ena		: in std_logic;
		trig	: in std_logic := '0';
        out_o	: out signed(15 downto 0)
    );
end entity;

architecture magic of dither_source is
	constant m		: unsigned(7 downto 0) := x"2F";
	signal tmp1		: unsigned(15 downto 0) := x"0080"; --seed
	signal tmp2		: unsigned(15+8 downto 0) := x"000080"; --seed
	signal ptrg		: std_logic := '0';
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			ptrg <= trig;

			if (ptrg='0' and trig='1') or (ptrg='1' and trig='0') then
				tmp2 <= m * tmp1 + 7;
				tmp1 <= tmp2(15 downto 0);
			end if;
		end if;
	end process;

	out_o <= resize(signed(tmp1(15 downto 8)), 16) when ena='1' else
		(others => '0');
end architecture;