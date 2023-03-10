-------------------------------------------------------------
-- Complex frequency modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fm_modulator is
	port(
		nrst	: in std_logic;						-- reset
		clk_i	: in std_logic;						-- main clock
		mod_i	: in std_logic_vector(15 downto 0);	-- modulation in
		dith_i	: in signed(15 downto 0);			-- phase dither input
		i_o		: out std_logic_vector(15 downto 0);-- I data out
		q_o		: out std_logic_vector(15 downto 0)	-- Q data out
	);
end fm_modulator;

architecture magic of fm_modulator is
	component sincos_16 is
		port(
			theta_i		:   in  std_logic_vector(9 downto 0);
			sine_o		:   out std_logic_vector(15 downto 0);
			cosine_o	:   out std_logic_vector(15 downto 0)
		);
	end component;
	
	component dither_adder is
		port(
			phase_i	: in unsigned(20 downto 0);
			dith_i	: in signed(15 downto 0);
			phase_o	: out unsigned(20 downto 0) := (others => '0')
		);
	end component;
	
	signal raw_i	: std_logic_vector(15 downto 0) := (others => '0');
	signal raw_q	: std_logic_vector(15 downto 0) := (others => '0');
	signal phase	: std_logic_vector(20 downto 0) := (others => '0');
	signal phased	: std_logic_vector(20 downto 0) := (others => '0');
begin
	-- sincos LUT
	sincos_lut0: sincos_16 port map(theta_i => phased(20 downto 11), sine_o => raw_q, cosine_o => raw_i);

	-- phase dither
	phase_dither0: dither_adder port map(
		phase_i => unsigned(phase),
		dith_i => dith_i,
		std_logic_vector(phase_o) => phased
	);

	process(clk_i)
		variable counter : integer range 0 to 30 := 0;
	begin
		if rising_edge(clk_i) then
			if nrst='1' then
				if counter=30-1 then
					phase <= std_logic_vector(unsigned(phase) + unsigned(mod_i(15) & mod_i(15) & mod_i(15) & mod_i(15) & mod_i(15) & mod_i)); -- update phase accumulator
					counter := 0;
					i_o <= raw_i;
					q_o <= raw_q;
				else
					counter := counter + 1;
				end if;
			else
				counter := 0;
				phase <= (others => '0');
			end if;
		end if;
	end process;
end magic;
