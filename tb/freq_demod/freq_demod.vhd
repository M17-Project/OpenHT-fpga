-------------------------------------------------------------
-- Frequency demodulator block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
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
	signal a_i, a_q : signed(16 downto 0) := (others => '0');
	signal m_i, m_q : signed(32 downto 0) := (others => '0');
	signal diff : signed(33 downto 0) := (others => '0');
	signal sum_sq : signed(32 downto 0) := (16 => '1', others => '0');
	signal res : signed(33 downto 0) := (others => '0');
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			-- delay line pushes
			dly_i(1) <= dly_i(0);
			dly_i(0) <= i_i;
			dly_q(1) <= dly_q(0);
			dly_q(0) <= q_i;
			demod_o <= res(15 downto 0);
		end if;
	end process;
	
	-- sum of squares
	sum_sq <= resize(i_i*i_i, 33) + q_i*q_i;
	-- add blocks
	a_i <= resize(i_i, 17) - dly_i(1);
	a_q <= resize(q_i, 17) - dly_q(1);
	-- multiply blocks
	m_i <= dly_i(0) * a_q;
	m_q <= dly_q(0) * a_i;
	-- result
	diff <= resize(m_i, 34) - m_q;
	res <= diff / sum_sq(32 downto 32-19+1) when signed(sum_sq(32 downto 32-19+1))/=0 else (others => '0');
end magic;
