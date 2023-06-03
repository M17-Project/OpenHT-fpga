-------------------------------------------------------------
-- Serial FIR channel filter set
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fir_channel_6_25 is
	generic(
		TAPS_NUM	: integer := 81;
		SAMP_WIDTH	: integer := 16
	);
	port(
		clk_i		: in std_logic;											-- fast clock in
		data_i		: in signed(SAMP_WIDTH-1 downto 0);						-- data in
		data_o		: out signed(SAMP_WIDTH-1 downto 0) := (others => '0');	-- data out
		trig_i		: in std_logic;											-- trigger in
		drdy_o		: out std_logic := '0'									-- data ready out
	);
end fir_channel_6_25;

architecture magic of fir_channel_6_25 is
	type arr_sig_t is array(integer range 0 to TAPS_NUM-1) of signed(SAMP_WIDTH-1 downto 0);
	constant taps : arr_sig_t := (
		x"FF00", x"00B6", x"00B7", x"00C9",
		x"00D7", x"00D1", x"00AD", x"0068",
		x"0006", x"FF90", x"FF18", x"FEB2",
		x"FE75", x"FE71", x"FEB3", x"FF3B",
		x"FFFD", x"00E2", x"01CA", x"028B",
		x"02FE", x"0302", x"0282", x"017C",
		x"0004", x"FE43", x"FC76", x"FAE8",
		x"F9E8", x"F9BF", x"FAA5", x"FCBA",
		x"FFFC", x"0447", x"0955", x"0EC4",
		x"141F", x"18EC", x"1CB8", x"1F28",
		x"2000", x"1F28", x"1CB8", x"18EC",
		x"141F", x"0EC4", x"0955", x"0447",
		x"FFFC", x"FCBA", x"FAA5", x"F9BF",
		x"F9E8", x"FAE8", x"FC76", x"FE43",
		x"0004", x"017C", x"0282", x"0302",
		x"02FE", x"028B", x"01CA", x"00E2",
		x"FFFD", x"FF3B", x"FEB3", x"FE71",
		x"FE75", x"FEB2", x"FF18", x"FF90",
		x"0006", x"0068", x"00AD", x"00D1",
		x"00D7", x"00C9", x"00B7", x"00B6",
		x"FF00"
	);
	
	signal dline : arr_sig_t := (others => (others => '0'));

	signal p_trig, pp_trig : std_logic := '0';
	signal busy : std_logic := '0';
	signal mac : signed(integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH-1 downto 0) := (others => '0');
	signal mul : signed(2*SAMP_WIDTH-1 downto 0) := (others => '0');
begin
	process(clk_i)
		variable counter : integer range 0 to TAPS_NUM+1 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			-- detect rising edge at the trig input
			if pp_trig='0' and p_trig='1' then
				-- update data register
				dline <= dline(1 to TAPS_NUM-1) & data_i;
				-- zero all stuff
				counter := 0;
				mul <= (others => '0');
				mac <= resize(data_i * taps(TAPS_NUM-1), integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH);
				-- assert busy flag
				busy <= '1';
			end if;

			if busy='1' then
				if counter=TAPS_NUM then
					-- output result
					data_o <= mac(2*SAMP_WIDTH-1 downto SAMP_WIDTH);
					-- deassert busy flag
					busy <= '0';
					-- zero the counter
					counter := 0;
				else
					-- perform some arithmetic
					mul <= dline(counter) * taps(counter);
					mac <= mac + mul;
					-- update the counter
					counter := counter + 1;
				end if;
			end if;
		end if;
	end process;

	drdy_o <= not busy;
end magic;

----------------------------------- 12.5k -----------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fir_channel_12_5 is
	generic(
		TAPS_NUM	: integer := 81;
		SAMP_WIDTH	: integer := 16
	);
	port(
		clk_i		: in std_logic;											-- fast clock in
		data_i		: in signed(SAMP_WIDTH-1 downto 0);						-- data in
		data_o		: out signed(SAMP_WIDTH-1 downto 0) := (others => '0');	-- data out
		trig_i		: in std_logic;											-- trigger in
		drdy_o		: out std_logic := '0'									-- data ready out
	);
end fir_channel_12_5;

architecture magic of fir_channel_12_5 is
	type arr_sig_t is array(integer range 0 to TAPS_NUM-1) of signed(SAMP_WIDTH-1 downto 0);
	constant taps : arr_sig_t := (
		x"0094", x"FED0", x"FF19", x"FF69",
		x"FFF6", x"0092", x"00E9", x"00B6",
		x"0000", x"FF26", x"FEAF", x"FEFC",
		x"FFFF", x"0133", x"01D9", x"016B",
		x"0001", x"FE55", x"FD71", x"FE09",
		x"FFFF", x"024F", x"038C", x"02BB",
		x"0001", x"FCC1", x"FAF8", x"FC16",
		x"FFFF", x"04CA", x"0792", x"0609",
		x"0001", x"F810", x"F2C6", x"F4AF",
		x"FFFF", x"1313", x"289F", x"3993",
		x"4000", x"3993", x"289F", x"1313",
		x"FFFF", x"F4AF", x"F2C6", x"F810",
		x"0001", x"0609", x"0792", x"04CA",
		x"FFFF", x"FC16", x"FAF8", x"FCC1",
		x"0001", x"02BB", x"038C", x"024F",
		x"FFFF", x"FE09", x"FD71", x"FE55",
		x"0001", x"016B", x"01D9", x"0133",
		x"FFFF", x"FEFC", x"FEAF", x"FF26",
		x"0000", x"00B6", x"00E9", x"0092",
		x"FFF6", x"FF69", x"FF19", x"FED0",
		x"0094"
	);
	
	signal dline : arr_sig_t := (others => (others => '0'));

	signal p_trig, pp_trig : std_logic := '0';
	signal busy : std_logic := '0';
	signal mac : signed(integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH-1 downto 0) := (others => '0');
	signal mul : signed(2*SAMP_WIDTH-1 downto 0) := (others => '0');
begin
	process(clk_i)
		variable counter : integer range 0 to TAPS_NUM+1 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			-- detect rising edge at the trig input
			if pp_trig='0' and p_trig='1' then
				-- update data register
				dline <= dline(1 to TAPS_NUM-1) & data_i;
				-- zero all stuff
				counter := 0;
				mul <= (others => '0');
				mac <= resize(data_i * taps(TAPS_NUM-1), integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH);
				-- assert busy flag
				busy <= '1';
			end if;

			if busy='1' then
				if counter=TAPS_NUM then
					-- output result
					data_o <= mac(2*SAMP_WIDTH-1 downto SAMP_WIDTH);
					-- deassert busy flag
					busy <= '0';
					-- zero the counter
					counter := 0;
				else
					-- perform some arithmetic
					mul <= dline(counter) * taps(counter);
					mac <= mac + mul;
					-- update the counter
					counter := counter + 1;
				end if;
			end if;
		end if;
	end process;

	drdy_o <= not busy;
end magic;

----------------------------------- 25k -----------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fir_channel_25 is
	generic(
		TAPS_NUM	: integer := 81;
		SAMP_WIDTH	: integer := 16
	);
	port(
		clk_i		: in std_logic;											-- fast clock in
		data_i		: in signed(SAMP_WIDTH-1 downto 0);						-- data in
		data_o		: out signed(SAMP_WIDTH-1 downto 0) := (others => '0');	-- data out
		trig_i		: in std_logic;											-- trigger in
		drdy_o		: out std_logic := '0'									-- data ready out
	);
end fir_channel_25;

architecture magic of fir_channel_25 is
	type arr_sig_t is array(integer range 0 to TAPS_NUM-1) of signed(SAMP_WIDTH-1 downto 0);
	constant taps : arr_sig_t := (
		x"0000", x"FE77", x"0000", x"00B0",
		x"0000", x"FF2A", x"0000", x"0103",
		x"0000", x"FEC9", x"0000", x"0172",
		x"0000", x"FE4B", x"0000", x"0203",
		x"0000", x"FDA2", x"0000", x"02C8",
		x"0000", x"FCBA", x"0000", x"03DE",
		x"0000", x"FB66", x"0000", x"0589",
		x"0000", x"F938", x"0000", x"0889",
		x"0000", x"F4C4", x"0000", x"1001",
		x"0000", x"E504", x"0000", x"516D",
		x"7FFF", x"516D", x"0000", x"E504",
		x"0000", x"1001", x"0000", x"F4C4",
		x"0000", x"0889", x"0000", x"F938",
		x"0000", x"0589", x"0000", x"FB66",
		x"0000", x"03DE", x"0000", x"FCBA",
		x"0000", x"02C8", x"0000", x"FDA2",
		x"0000", x"0203", x"0000", x"FE4B",
		x"0000", x"0172", x"0000", x"FEC9",
		x"0000", x"0103", x"0000", x"FF2A",
		x"0000", x"00B0", x"0000", x"FE77",
		x"0000"
	);
	
	signal dline : arr_sig_t := (others => (others => '0'));

	signal p_trig, pp_trig : std_logic := '0';
	signal busy : std_logic := '0';
	signal mac : signed(integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH-1 downto 0) := (others => '0');
	signal mul : signed(2*SAMP_WIDTH-1 downto 0) := (others => '0');
begin
	process(clk_i)
		variable counter : integer range 0 to TAPS_NUM+1 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			-- detect rising edge at the trig input
			if pp_trig='0' and p_trig='1' then
				-- update data register
				dline <= dline(1 to TAPS_NUM-1) & data_i;
				-- zero all stuff
				counter := 0;
				mul <= (others => '0');
				mac <= resize(data_i * taps(TAPS_NUM-1), integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH);
				-- assert busy flag
				busy <= '1';
			end if;

			if busy='1' then
				if counter=TAPS_NUM then
					-- output result
					data_o <= mac(2*SAMP_WIDTH-1 downto SAMP_WIDTH);
					-- deassert busy flag
					busy <= '0';
					-- zero the counter
					counter := 0;
				else
					-- perform some arithmetic
					mul <= dline(counter) * taps(counter);
					mac <= mac + mul;
					-- update the counter
					counter := counter + 1;
				end if;
			end if;
		end if;
	end process;

	drdy_o <= not busy;
end magic;
