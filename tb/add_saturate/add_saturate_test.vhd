--add_saturate test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity add_saturate_test is
	--
end add_saturate_test;

architecture sim of add_saturate_test is
	component add_saturate is
		port(
			a_i : in std_logic_vector(15 downto 0);
			b_i : in std_logic_vector(15 downto 0);
			s_o : out std_logic_vector(15 downto 0)
		);
	end component;

	signal a_i, b_i : std_logic_vector(15 downto 0) := x"8000";
	signal s_o : std_logic_vector(15 downto 0) := (others => '0');
begin
	dut: add_saturate port map(a_i => a_i, b_i => b_i, s_o => s_o);

	process
	begin
		wait for 1 ms;
		a_i <= std_logic_vector(signed(a_i)+5);
		b_i <= std_logic_vector(signed(a_i)+5);
	end process;
end sim;
