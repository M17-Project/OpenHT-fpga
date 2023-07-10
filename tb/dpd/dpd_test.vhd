--dpd test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dpd_test is
	--
end dpd_test;

architecture sim of dpd_test is
	component dpd is
		port(
			-- p1*x + p2*|x|^2 + p3*x^3
			p1 : in signed(15 downto 0);
			p2 : in signed(15 downto 0);
			p3 : in signed(15 downto 0);
			i_i : in std_logic_vector(15 downto 0);
			q_i : in std_logic_vector(15 downto 0);
			i_o: out std_logic_vector(15 downto 0);
			q_o: out std_logic_vector(15 downto 0)
		);
	end component;

	signal p1	: signed(15 downto 0) := x"3D00"; --0x4000 is "+1.00"
	signal p2	: signed(15 downto 0) := x"0020";
	signal p3	: signed(15 downto 0) := x"1000";
	signal i_i	: std_logic_vector(15 downto 0) := x"8000";
	signal q_i	: std_logic_vector(15 downto 0) := x"8000";
	signal i_o	: std_logic_vector(15 downto 0);
	signal q_o	: std_logic_vector(15 downto 0);
begin
	dut: dpd port map(p1 => p1, p2 => p2, p3 => p3,
		i_i => i_i, q_i => q_i, i_o => i_o, q_o => q_o);

	process
	begin
		wait for 1 us;
		i_i <= std_logic_vector(unsigned(i_i) + 1);
		q_i <= std_logic_vector(unsigned(q_i) + 1);
	end process;

	--process
	--begin
		--clk_i <= not clk_i;
		--wait for 0.1 ms;
	--end process;
end sim;
