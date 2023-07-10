--IQ offset
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_offset is
	port(
		i_i : in std_logic_vector(15 downto 0);
		q_i : in std_logic_vector(15 downto 0);
		ai_i : in std_logic_vector(15 downto 0);
		aq_i : in std_logic_vector(15 downto 0);
		i_o : out std_logic_vector(15 downto 0);
		q_o : out std_logic_vector(15 downto 0)
	);
end iq_offset;

architecture magic of iq_offset is
	signal iext_sum, qext_sum : std_logic_vector(16 downto 0) := (others => '0'); -- bit extended sum
begin
	iext_sum <= std_logic_vector(signed(i_i(15) & i_i(15 downto 0)) + signed(ai_i(15) & ai_i(15 downto 0)));
	qext_sum <= std_logic_vector(signed(q_i(15) & q_i(15 downto 0)) + signed(aq_i(15) & aq_i(15 downto 0)));
	
	i_o <= x"8000" when (signed(iext_sum)<-32768) else
		x"7FFF" when (signed(iext_sum)>32767) else
		iext_sum(15 downto 0);
	q_o <= x"8000" when (signed(qext_sum)<-32768) else
		x"7FFF" when (signed(qext_sum)>32767) else
		qext_sum(15 downto 0);
end magic;
