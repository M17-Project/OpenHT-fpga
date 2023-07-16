-------------------------------------------------------------
-- CTCSS encoder block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ctcss_encoder is
	generic(
		SINCOS_RES 		: natural := 16;			-- CORDIC resolution, default - 16 bits
		SINCOS_ITER		: natural := 14;			-- CORDIC iterations, default - 14
		SINCOS_COEFF	: signed := x"4DB9"			-- CORDIC scaling coefficient		
	);
	port(
		clk_i	: in std_logic;						-- main clock in
		nrst	: in std_logic;						-- reset
		trig_i	: in std_logic;						-- trigger input, 400k
		ctcss_i	: in std_logic_vector(5 downto 0);	-- CTCSS in
		ctcss_o	: out std_logic_vector(15 downto 0)	-- CTCSS tone out
	);
end ctcss_encoder;

architecture magic of ctcss_encoder is
	type ctcss_f is array(0 to 50) of std_logic_vector(20 downto 0);
	
	constant ctcss_lut : ctcss_f := (
        21x"000000", -- no CTCSS
		21x"00015F", -- 67.0
		21x"00016B", -- 69.3
		21x"000179", -- 71.9
		21x"000186", -- 74.4
		21x"000194", -- 77.0
		21x"0001A2", -- 79.7
		21x"0001B1", -- 82.5
		21x"0001C0", -- 85.4
		21x"0001D0", -- 88.5
		21x"0001E0", -- 91.5
		21x"0001F1", -- 94.8
		21x"0001FF", -- 97.4
		21x"00020C", -- 100.0
		21x"00021F", -- 103.5
		21x"000232", -- 107.2
		21x"000245", -- 110.9
		21x"00025A", -- 114.8
		21x"00026F", -- 118.8
		21x"000285", -- 123.0
		21x"00029B", -- 127.3
		21x"0002B3", -- 131.8
		21x"0002CC", -- 136.5
		21x"0002E5", -- 141.3
		21x"0002FF", -- 146.2
		21x"00031A", -- 151.4
		21x"000336", -- 156.7
		21x"000346", -- 159.8
		21x"000352", -- 162.2
		21x"000364", -- 165.5
		21x"000370", -- 167.9
		21x"000382", -- 171.3
		21x"00038F", -- 173.8
		21x"0003A2", -- 177.3
		21x"0003AF", -- 179.9
		21x"0003C2", -- 183.5
		21x"0003D0", -- 186.2
		21x"0003E4", -- 189.9
		21x"0003F3", -- 192.8
		21x"000407", -- 196.6
		21x"000416", -- 199.5
		21x"00042B", -- 203.5
		21x"00043B", -- 206.5
		21x"000451", -- 210.7
		21x"000477", -- 218.1
		21x"00049F", -- 225.7
		21x"0004B1", -- 229.1
		21x"0004C9", -- 233.6
		21x"000534", -- 254.1
		21x"000520", -- 250.3
		21x"0004F4"  -- 241.8
	);
	
	signal raw_r		: std_logic_vector(15 downto 0) := (others => '0');
	signal phase		: std_logic_vector(20 downto 0) := (others => '0');
begin
	-- sincos
	sincos: entity work.cordic generic map(
        RES_WIDTH => SINCOS_RES,
        ITER_NUM => SINCOS_ITER,
        COMP_COEFF => SINCOS_COEFF
    )
	port map(
		clk_i => clk_i,
		phase_i => unsigned(phase(20 downto 20-16+1)),
		std_logic_vector(sin_o) => raw_r,
		cos_o => open,
		valid_o => open
	);

	process(trig_i)
	begin
		if rising_edge(trig_i) then
			if nrst='1' and ctcss_i/="000000" then
				phase <= std_logic_vector(unsigned(phase) + unsigned(ctcss_lut(to_integer(unsigned(ctcss_i))))); -- update phase accumulator
			else
				phase <= (others => '0');
			end if;
			ctcss_o <= std_logic_vector(resize(signed(raw_r(15 downto 4)), 16));
		end if;
	end process;
end magic;
