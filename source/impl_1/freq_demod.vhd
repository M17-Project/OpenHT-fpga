--freq_demod
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity freq_demod is
	port(
		clk_i		: in std_logic;									-- demod clock
		i_i, q_i	: in signed(15 downto 0);						-- I/Q inputs
		demod_o		: out signed(15 downto 0) := (others => '0')	-- freq demod out
	);
end freq_demod;

architecture magic of freq_demod is
	type delay_line is array(0 to 1) of signed(15 downto 0);
	signal dly_i, dly_q : delay_line := (others => (others => '0'));
	signal a_i, a_q : signed(15 downto 0) := (others => '0'); -- is 16 bits enough?
	signal m_i, m_q, diff : signed(31 downto 0) := (others => '0');
	signal sum_sq : signed(31 downto 0) := (0 => '1', others => '0');
	signal res : signed(31 downto 0) := (others => '0');
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			-- delay line pushes
			dly_i(1) <= dly_i(0);
			dly_i(0) <= i_i;
			dly_q(1) <= dly_q(0);
			dly_q(0) <= q_i;
		end if;
	end process;
	
	-- sum of squares
	sum_sq <= i_i*i_i + q_i*q_i;
	-- add blocks
	a_i <= i_i - dly_i(1);
	a_q <= q_i - dly_q(1);
	-- multiply blocks
	m_i <= dly_i(0) * a_q;
	m_q <= dly_q(0) * a_i;
	-- result
	diff <= m_i - m_q;
	res <= diff / sum_sq(31 downto 16);
	demod_o <= res(16 downto 1);
end magic;
