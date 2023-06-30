-------------------------------------------------------------
-- Complex frequency modulator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fm_modulator is
	generic(
		SINCOS_RES : natural := 10					-- sincos LUT bit resolution, default - 10 bits
	);
	port(
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
	
	--component sincos_cordic is
		--port(
			--clk_i		: in std_logic;
			--inpvalid_i	: in std_logic;
			--phasein_i	: in std_logic_vector(15 downto 0);
			--rst_n_i		: in std_logic;
			--outvalid_o	: out std_logic;
			--rfi_o		: out std_logic;
			--xout_o		: out std_logic_vector(15 downto 0);
			--yout_o		: out std_logic_vector(15 downto 0)
		--);
	--end component;
	
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
	sincos_lut0: sincos_lut generic map(
		LUT_SIZE => 2**SINCOS_RES,
		WORD_SIZE => 16
	)
	port map(
		clk_i => trig_i,
		theta_i => phased(20 downto 20-SINCOS_RES+1),
		sine_o => raw_q,
		cosine_o => raw_i
	);
	
	--sincos_lut0: sincos_cordic port map(
		--clk_i		=> clk_i,
		--inpvalid_i	=> '1',
		--phasein_i	=> phased(20 downto 20-16+1),
		--rst_n_i		=> '1',
		----outvalid_o	=> ,
		----rfi_o		=> ,
		--xout_o		=> raw_i,
		--yout_o		=> raw_q
	--);

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
