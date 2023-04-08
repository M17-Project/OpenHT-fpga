-------------------------------------------------------------
-- Phase modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- April 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pm_modulator is
	port(
		mod_i	: in std_logic_vector(15 downto 0);	-- modulation in
		i_o		: out std_logic_vector(15 downto 0);-- I data out
		q_o		: out std_logic_vector(15 downto 0)	-- Q data out
	);
end pm_modulator;

architecture magic of pm_modulator is
	component sincos_16 is
		port(
			theta_i		:   in  std_logic_vector(9 downto 0);
			sine_o		:   out std_logic_vector(15 downto 0);
			cosine_o	:   out std_logic_vector(15 downto 0)
		);
	end component;
begin
	-- sincos LUT
	sincos_lut0: sincos_16 port map(theta_i => mod_i(15 downto 6), sine_o => q_o, cosine_o => i_o);
end magic;
