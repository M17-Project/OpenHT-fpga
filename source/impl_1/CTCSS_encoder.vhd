-------------------------------------------------------------
-- CTCSS encoder block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- April 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ctcss_encoder is
	port(
		nrst	: in std_logic;						-- reset
		trig_i	: in std_logic;						-- trigger input, 400k
		clk_i	: in std_logic;						-- main clock
		ctcss_i	: in std_logic_vector(5 downto 0);	-- CTCSS in
		ctcss_o	: out std_logic_vector(15 downto 0)	-- CTCSS tone out
	);
end ctcss_encoder;

architecture magic of ctcss_encoder is
	type ctcss_f is array(0 to 2) of std_logic_vector(20 downto 0);
	
	constant ctcss_lut : ctcss_f := ( -- TODO: fill this with all 50 values
        '0' & x"00000",	-- no CTCSS
		'0' & x"0029B",	-- 127.3
		'0' & x"0042B"	-- 203.5
	);

	component sincos_16 is
		port(
			theta_i		:   in  std_logic_vector(9 downto 0);
			sine_o		:   out std_logic_vector(15 downto 0);
			cosine_o	:   out std_logic_vector(15 downto 0)
		);
	end component;
	
	signal raw_r				: std_logic_vector(15 downto 0) := (others => '0');
	signal phase				: std_logic_vector(20 downto 0) := (others => '0');
	signal p_trig_i, pp_trig_i	: std_logic := '0';
begin
	-- sincos LUT
	sincos_lut0: sincos_16 port map(
		theta_i => phase(20 downto 11),
		sine_o => raw_r
		--cosine_o =>
	);

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			p_trig_i <= trig_i;
			pp_trig_i <= p_trig_i;
			
			if nrst='1' then
				if pp_trig_i='0' and p_trig_i='1' then
					phase <= std_logic_vector(unsigned(phase) + unsigned(ctcss_lut(to_integer(unsigned(ctcss_i))))); -- update phase accumulator
					ctcss_o <= std_logic_vector(resize(signed(raw_r(15 downto 4)), 16));
				end if;
			else
				phase <= (others => '0');
			end if;
		end if;
	end process;
end magic;
