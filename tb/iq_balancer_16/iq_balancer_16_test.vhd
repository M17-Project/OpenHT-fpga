--iq_balancer_16 test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_balancer_16_test is
	--
end iq_balancer_16_test;

architecture sim of iq_balancer_16_test is
	component iq_balancer_16 is
		port(
			i_i		: in std_logic_vector(15 downto 0);			-- I data in
			q_i		: in std_logic_vector(15 downto 0);			-- Q data in
			ib_i	: in std_logic_vector(15 downto 0);			-- I balance in, 0x4000 = "+1.0"
			qb_i	: in std_logic_vector(15 downto 0);			-- Q balance in, 0x4000 = "+1.0"
			i_o		: out std_logic_vector(15 downto 0);		-- I data in
			q_o		: out std_logic_vector(15 downto 0)			-- Q data in
		);
	end component;

	signal i_i		: std_logic_vector(15 downto 0) := x"8000";
	signal q_i		: std_logic_vector(15 downto 0) := x"8000";
	signal ib_i		: std_logic_vector(15 downto 0) := x"6000";
	signal qb_i		: std_logic_vector(15 downto 0) := x"4000";
	signal i_o		: std_logic_vector(15 downto 0) := (others => '0');
	signal q_o		: std_logic_vector(15 downto 0) := (others => '0');
begin
	dut: iq_balancer_16 port map(
		i_i => i_i,
		q_i => q_i,
		ib_i => ib_i,
		qb_i => qb_i,
		i_o => i_o,
		q_o => q_o
	);

	process
	begin
		wait for 0.0015 ms;
		i_i <= std_logic_vector(unsigned(i_i)+1);
	end process;
end sim;
