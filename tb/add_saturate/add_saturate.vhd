--add_saturate
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity add_saturate is
	port(
		a_i : in std_logic_vector(15 downto 0);
		b_i : in std_logic_vector(15 downto 0);
		s_o : out std_logic_vector(15 downto 0)
	);
end add_saturate;

architecture magic of add_saturate is
	signal ext_sum : std_logic_vector(16 downto 0) := (others => '0'); -- bit extended sum
begin
	ext_sum <= std_logic_vector(signed(a_i(15) & a_i(15 downto 0)) + signed(b_i(15) & b_i(15 downto 0)));
	s_o <= x"8000" when (signed(ext_sum)<-32768) else
		x"7FFF" when (signed(ext_sum)>32767) else
		ext_sum(15 downto 0);
end magic;
