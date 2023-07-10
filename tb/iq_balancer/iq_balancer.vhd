--IQ balancer
--AT86RF215 debug mode
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_balancer is
	port(
		i_i		: in std_logic_vector(7 downto 0);			-- I data in
		q_i		: in std_logic_vector(7 downto 0);			-- Q data in
		ib_i	: in std_logic_vector(15 downto 0);			-- I balance in
		qb_i	: in std_logic_vector(15 downto 0);			-- Q balance in
		i_o		: out std_logic_vector(7 downto 0);			-- I data in
		q_o		: out std_logic_vector(7 downto 0)			-- Q data in
	);
end iq_balancer;

architecture magic of iq_balancer is
	signal i_raw	: std_logic_vector(7 downto 0);
	signal q_raw	: std_logic_vector(7 downto 0);
	signal i_o_raw	: std_logic_vector(8+17-1 downto 0);
	signal q_o_raw	: std_logic_vector(8+17-1 downto 0);
begin
	--process
	--begin
		i_raw <= '0' & i_i(6 downto 0);
		q_raw <= '0' & q_i(6 downto 0);
		
		i_o_raw <= std_logic_vector((signed(i_raw)-16#3F#) * signed('0' & ib_i) + 16#1F8000#);
		q_o_raw <= std_logic_vector((signed(q_raw)-16#3F#) * signed('0' & qb_i) + 16#1F8000#);
		
		-- apply rounding
		i_o <= '1' & std_logic_vector(unsigned(i_o_raw(21 downto 15))+1) when i_o_raw(14)='1' else '1' & i_o_raw(21 downto 15);
		q_o <= '1' & std_logic_vector(unsigned(q_o_raw(21 downto 15))+1) when q_o_raw(14)='1' else '1' & q_o_raw(21 downto 15);
	--end process;
end magic;
