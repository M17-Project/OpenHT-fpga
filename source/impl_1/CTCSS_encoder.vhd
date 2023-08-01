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
use work.axi_stream_pkg.all;

entity ctcss_encoder is
	generic(
		SINCOS_RES 		: natural := 16;			-- CORDIC resolution, default - 16 bits
		SINCOS_ITER		: natural := 14;			-- CORDIC iterations, default - 14
		SINCOS_COEFF	: signed := x"4DB9"			-- CORDIC scaling coefficient		
	);
	port(
		clk_i			: in std_logic;						-- main clock in
		nrst_i			: in std_logic;						-- reset
		ctcss_i			: in std_logic_vector(5 downto 0);	-- CTCSS code in
		m_axis_mod_i	: in axis_out_mod_t;
		m_axis_mod_o	: out axis_in_mod_t
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
	signal ready		: std_logic := '0';
	signal cordic_valid : std_logic := '0';
	signal output_valid	: std_logic := '0';
	signal ctcss_cntr : unsigned(7 downto 0) := (others => '0');
	signal ctcss_increment : std_logic;
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
		phase_valid_i => ctcss_increment,
		std_logic_vector(sin_o) => raw_r,
		cos_o => open,
		valid_o => cordic_valid
	);
	m_axis_mod_o.tdata <= std_logic_vector(resize(signed(raw_r(15 downto 4)), 16));
	
	process(clk_i)
	begin
		if nrst_i='0' then
			phase <= (others => '0');
		elsif rising_edge(clk_i) then
			ctcss_increment <= '0';
			if ctcss_cntr >= 160-1 then -- 64 / 0.4 = 160
				ctcss_cntr <= (others => '0');
				ctcss_increment <= '1';
			else
				ctcss_cntr <= ctcss_cntr + 1;
			end if;

			-- when data is computed, set output to 1
			if cordic_valid then
				output_valid <= '1';
			end if;
			
			-- when consumed by downstream, allow new data to enter
			if m_axis_mod_i.tready and output_valid then
				output_valid <= '0';
			end if;	
			
			-- update phase
			if ctcss_increment then
				if ctcss_i/="000000" then
					phase <= std_logic_vector(unsigned(phase) + unsigned(ctcss_lut(to_integer(unsigned(ctcss_i))))); -- update phase accumulator
				else
					phase <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	
	m_axis_mod_o.tvalid <= output_valid;
end magic;
