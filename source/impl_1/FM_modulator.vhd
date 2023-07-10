-------------------------------------------------------------
-- Complex frequency modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fm_modulator is
	generic(
		SINCOS_RES 		: natural := 16;			-- CORDIC resolution, default - 16 bits
		SINCOS_ITER		: natural := 14;			-- CORDIC iterations, default - 14
		SINCOS_COEFF	: signed := x"4DB9"			-- CORDIC scaling coefficient
	);
	port(
		clk_i	: in std_logic;						-- main clock in
		trig_i	: in std_logic;						-- 400k trigger
		nrst	: in std_logic;						-- reset
		mod_i	: in std_logic_vector(15 downto 0);	-- modulation in
		dith_i	: in signed(15 downto 0);			-- phase dither input
		nw_i	: in std_logic;						-- narrow/wide selector, N=0, W=1
		i_o		: out std_logic_vector(15 downto 0);-- I data out
		q_o		: out std_logic_vector(15 downto 0)	-- Q data out
	);
end fm_modulator;

architecture magic of fm_modulator is
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
	signal theta	: unsigned(15 downto 0) := (others => '0');
begin
	-- sincos
	theta <= unsigned(phased(20 downto 20-16+1)) when rising_edge(trig_i);
	sincos: entity work.cordic generic map(
        RES_WIDTH => SINCOS_RES,
        ITER_NUM => SINCOS_ITER,
        COMP_COEFF => SINCOS_COEFF
    )
	port map(
		clk_i => clk_i,
		phase_i => theta,
		std_logic_vector(sin_o) => raw_q,
		std_logic_vector(cos_o) => raw_i,
		trig_o => open
	);
	
	-- phase dither
	phase_dither0: dither_adder port map(
		phase_i => unsigned(phase),
		dith_i => dith_i,
		std_logic_vector(phase_o) => phased
	);

	process(trig_i)
	begin
		if rising_edge(trig_i) then
			if nrst='1' then
				if nw_i='0' then -- narrow FM
					phase <= std_logic_vector(unsigned(phase) + unsigned(resize(signed(mod_i), 21))); -- update phase accumulator
				else -- wide FM
					phase <= std_logic_vector(unsigned(phase) + unsigned(resize(signed(mod_i & '0'), 21))); -- update phase accumulator
				end if;
					
				i_o <= raw_i;
				q_o <= raw_q;
			else
				phase <= (others => '0');
			end if;
		end if;
	end process;
end magic;
