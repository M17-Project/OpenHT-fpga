-------------------------------------------------
-- IQ polynomial digital predistortion model
--
-- p1*x + p2*sgn(x)*x^2 + p3*x^3
-- 0x4000 is "+1.00"
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July  2023
-------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dpd is
	port(
		clk_i : in std_logic;
		p1 : in signed(15 downto 0);
		p2 : in signed(15 downto 0);
		p3 : in signed(15 downto 0);
		i_i : in std_logic_vector(15 downto 0);
		q_i : in std_logic_vector(15 downto 0);
		i_o: out std_logic_vector(15 downto 0);
		q_o: out std_logic_vector(15 downto 0)
	);
end dpd;

architecture magic of dpd is
	signal i1 : std_logic_vector(31 downto 0) := (others => '0');
	signal i2 : std_logic_vector(47 downto 0) := (others => '0');
	signal i3 : std_logic_vector(63 downto 0) := (others => '0');
	signal imul : std_logic_vector(31 downto 0) := (others => '0');
	signal iesum : std_logic_vector(17 downto 0) := (others => '0'); --bit extended sum (16->18)

	signal q1 : std_logic_vector(31 downto 0) := (others => '0');
	signal q2 : std_logic_vector(47 downto 0) := (others => '0');
	signal q3 : std_logic_vector(63 downto 0) := (others => '0');
	signal qmul : std_logic_vector(31 downto 0) := (others => '0');
	signal qesum : std_logic_vector(17 downto 0) := (others => '0'); --bit extended sum (16->18)
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			q_o <= x"8000" when (signed(qesum)<-32768) else
				x"7FFF" when (signed(qesum)>32767) else
				qesum(15 downto 0);
		end if;
	end process;

	imul <= std_logic_vector(signed(i_i) * signed(i_i));
	i1 <= std_logic_vector(signed(i_i) * p1);
	i2 <= std_logic_vector(signed(imul) * p2) when signed(i_i)>=0 else std_logic_vector(-signed(imul) * p2);
	i3 <= std_logic_vector(signed(imul) * signed(i_i) * p3);
	iesum <= std_logic_vector(signed(i1(29) & i1(29) & i1(29 downto 14)) + signed(i2(43) & i2(43) & i2(43 downto 28)) + signed(i3(57) & i3(57) & i3(57 downto 42)));
	i_o <= x"8000" when (signed(iesum)<-32768) else
		x"7FFF" when (signed(iesum)>32767) else
		iesum(15 downto 0);

	qmul <= std_logic_vector(signed(q_i) * signed(q_i));
	q1 <= std_logic_vector(signed(q_i) * p1);
	q2 <= std_logic_vector(signed(qmul) * p2) when signed(q_i)>=0 else std_logic_vector(-signed(qmul) * p2);
	q3 <= std_logic_vector(signed(qmul) * signed(q_i) * p3);
	qesum <= std_logic_vector(signed(q1(29) & q1(29) & q1(29 downto 14)) + signed(q2(43) & q2(43) & q2(43 downto 28)) + signed(q3(57) & q3(57) & q3(57 downto 42)));
end magic;
