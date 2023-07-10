--local_osc test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity local_osc_test is
	--
end local_osc_test;

architecture sim of local_osc_test is
	component local_osc is
		generic(
			DIV			: integer := 10
		);
		port(
			trig_i		: in std_logic;
			i_o, q_o	: out signed(15 downto 0)
		);
	end component;

	signal clk_i : std_logic := '1';
	signal i_r, q_r : signed(15 downto 0) := (others => '0');
begin
	dut: local_osc port map(
		trig_i => clk_i,
		i_o => i_r,
		q_o => q_r
	);

	--process
	--begin
		--
	--end process;

	process
	begin
		wait for 0.1 ms;
		clk_i <= not clk_i;
	end process;
end sim;
