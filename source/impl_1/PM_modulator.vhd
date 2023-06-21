-------------------------------------------------------------
-- Phase modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pm_modulator is
	port(
		clk_i	: in std_logic;
		mod_i	: in std_logic_vector(15 downto 0);	-- modulation in
		i_o		: out std_logic_vector(15 downto 0);-- I data out
		q_o		: out std_logic_vector(15 downto 0)	-- Q data out
	);
end pm_modulator;

architecture magic of pm_modulator is
	component sincos_lut is
		generic(
			LUT_SIZE    : natural;
			WORD_SIZE   : natural
		);
		port(
			clk_i		: in std_logic;
			theta_i		: in std_logic_vector;
			sine_o		: out std_logic_vector;
			cosine_o	: out std_logic_vector
		);
	end component;
begin
	-- sincos LUT
	sincos_lut0: sincos_lut generic map(
		LUT_SIZE => 256*4,
		WORD_SIZE => 16
	)
	port map(
		clk_i => clk_i,
		theta_i => mod_i(15 downto 6),
		sine_o => q_o,
		cosine_o => i_o
	);
end magic;
