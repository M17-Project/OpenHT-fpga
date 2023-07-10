--IQ balancer test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_balancer_test is
	--
end iq_balancer_test;

architecture sim of iq_balancer_test is
	component iq_balancer is
		port(
			i_i		: in std_logic_vector(7 downto 0);			-- I data in
			q_i		: in std_logic_vector(7 downto 0);			-- Q data in
			ib_i	: in std_logic_vector(15 downto 0);			-- I balance in
			qb_i	: in std_logic_vector(15 downto 0);			-- Q balance in
			i_o		: out std_logic_vector(7 downto 0);			-- I data in
			q_o		: out std_logic_vector(7 downto 0)			-- Q data in
		);
	end component;

	signal i_i	: std_logic_vector(7 downto 0) := x"B0";
	signal q_i	: std_logic_vector(7 downto 0) := x"B0";
	signal ib_i	: std_logic_vector(15 downto 0) := x"0FFF"; -- x1.5
	signal qb_i	: std_logic_vector(15 downto 0) := x"8000";	-- x1.0
	signal i_o	: std_logic_vector(7 downto 0) := (others => '0');
	signal q_o	: std_logic_vector(7 downto 0) := (others => '0');
begin
	dut: iq_balancer port map(i_i => i_i, q_i => q_i,
		ib_i => ib_i, qb_i => qb_i,
		i_o => i_o, q_o => q_o);

	process
	begin
		for i in 0 to 31 loop
			if i>0 then
				i_i <= std_logic_vector(unsigned(i_i)+1);
				q_i <= std_logic_vector(unsigned(q_i)+1);
			end if;
			--ib_i <= x"0180";
			--qb_i <= x"0100";
			wait for 1 ms;
		end loop;
	end process;
end sim;
