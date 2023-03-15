-------------------------------------------------------------
-- I/Q balancer block
--
-- out = in * bal/0x4000
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_balancer_16 is
	port(
		i_i		: in std_logic_vector(15 downto 0);			-- I data in
		q_i		: in std_logic_vector(15 downto 0);			-- Q data in
		ib_i	: in std_logic_vector(15 downto 0);			-- I balance in, 0x4000 = "+1.0"
		qb_i	: in std_logic_vector(15 downto 0);			-- Q balance in, 0x4000 = "+1.0"
		i_o		: out std_logic_vector(15 downto 0);		-- I data out
		q_o		: out std_logic_vector(15 downto 0)			-- Q data out
	);
end iq_balancer_16;

architecture magic of iq_balancer_16 is
	signal i_o_raw	: std_logic_vector(16+16-1 downto 0) := (others => '0');
	signal q_o_raw	: std_logic_vector(16+16-1 downto 0) := (others => '0');
begin
	--process
	--begin
		i_o_raw <= std_logic_vector(signed(i_i) * signed(ib_i));
		q_o_raw <= std_logic_vector(signed(q_i) * signed(qb_i));
		
		-- apply rounding and limiting
		i_o <= x"8000" when signed(i_o_raw(31 downto 14))<-32768 else
			x"7FFF" when signed(i_o_raw(31 downto 14))>32767-1 else
			std_logic_vector(unsigned(i_o_raw(29 downto 14))+1) when i_o_raw(13)='1' else
			i_o_raw(29 downto 14);
		q_o <= x"8000" when signed(q_o_raw(31 downto 14))<-32768 else
			x"7FFF" when signed(q_o_raw(31 downto 14))>32767-1 else
			std_logic_vector(unsigned(q_o_raw(29 downto 14))+1) when q_o_raw(13)='1' else
			q_o_raw(29 downto 14);
	--end process;
end magic;