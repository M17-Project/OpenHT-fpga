-------------------------------------------------------------
-- CTCSS encoder block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- May 2023
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
	type ctcss_f is array(0 to 50) of std_logic_vector(20 downto 0);
	
	-- formula for the tuning word: W = round(f/400e3*2^21)
	constant ctcss_lut : ctcss_f := (
		'0' & x"00000",	-- no CTCSS
		'0' & x"0015F", -- 67.0
		'0' & x"0016B", -- 69.3
		'0' & x"00179", -- 71.9
		'0' & x"00186", -- 74.4
		'0' & x"00194", -- 77.0
		'0' & x"001A2", -- 79.7
		'0' & x"001B1", -- 82.5
		'0' & x"001C0", -- 85.4
		'0' & x"001D0", -- 88.5
		'0' & x"001E0", -- 91.5
		'0' & x"001F1", -- 94.8
		'0' & x"001FF", -- 97.4
		'0' & x"0020C", -- 100.0
		'0' & x"0021F", -- 103.5
		'0' & x"00232", -- 107.2
		'0' & x"00245", -- 110.9
		'0' & x"0025A", -- 114.8
		'0' & x"0026F", -- 118.8
		'0' & x"00285", -- 123.0
		'0' & x"0029B", -- 127.3
		'0' & x"002B3", -- 131.8
		'0' & x"002CC", -- 136.5
		'0' & x"002E5", -- 141.3
		'0' & x"002FF", -- 146.2
		'0' & x"0031A", -- 151.4
		'0' & x"00336", -- 156.7
		'0' & x"00346", -- 159.8
		'0' & x"00352", -- 162.2
		'0' & x"00364", -- 165.5
		'0' & x"00370", -- 167.9
		'0' & x"00382", -- 171.3
		'0' & x"0038F", -- 173.8
		'0' & x"003A2", -- 177.3
		'0' & x"003AF", -- 179.9
		'0' & x"003C2", -- 183.5
		'0' & x"003D0", -- 186.2
		'0' & x"003E4", -- 189.9
		'0' & x"003F3", -- 192.8
		'0' & x"00407", -- 196.6
		'0' & x"00416", -- 199.5
		'0' & x"0042B", -- 203.5
		'0' & x"0043B", -- 206.5
		'0' & x"00451", -- 210.7
		'0' & x"00477", -- 218.1
		'0' & x"0049F", -- 225.7
		'0' & x"004B1", -- 229.1
		'0' & x"004C9", -- 233.6
		'0' & x"004F4", -- 241.8
		'0' & x"00520", -- 250.3
		'0' & x"00534"  -- 254.1
	);

	component sincos_16 is
		port(
			theta_i		:   in  std_logic_vector(9 downto 0);
			sine_o		:   out std_logic_vector(15 downto 0);
			cosine_o	:   out std_logic_vector(15 downto 0)
		);
	end component;
	
	signal raw_r			: std_logic_vector(15 downto 0) := (others => '0');
	signal phase			: std_logic_vector(20 downto 0) := (others => '0');
	signal p_trig_i, pp_trig_i	: std_logic := '0';
begin
	-- sincos LUT
	sincos_lut0: sincos_16 port map(
		theta_i => phase(20 downto 11),
		sine_o => raw_r
		--cosine_o => -- unused
	);

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			p_trig_i <= trig_i;
			pp_trig_i <= p_trig_i;
			
			if nrst='1' then
				if pp_trig_i='0' and p_trig_i='1' then
					if unsigned(ctcss_i)<=50 then
						phase <= std_logic_vector(unsigned(phase) + unsigned(ctcss_lut(to_integer(unsigned(ctcss_i))))); -- update phase accumulator
					else
						phase <= (others => '0');
					end if;
					
					ctcss_o <= std_logic_vector(resize(signed(raw_r(15 downto 4)), 16));
				end if;
			else
				phase <= (others => '0');
			end if;
		end if;
	end process;
end magic;
