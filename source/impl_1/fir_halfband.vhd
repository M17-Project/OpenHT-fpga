-------------------------------------------------------------
-- Serial FIR halfband filter
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fir_halfband is
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
end fir_halfband;

architecture magic of fir_halfband is
	type arr_sig_t is array(integer range 0 to TAPS_NUM-1) of signed(SAMP_WIDTH-1 downto 0);
	constant taps : arr_sig_t := (
		x"0000", x"FE68", x"0000", x"00B3",
		x"0000", x"FF26", x"0000", x"0107",
		x"0000", x"FEC5", x"0000", x"0175",
		x"0000", x"FE47", x"0000", x"0207",
		x"0000", x"FD9F", x"0000", x"02CB",
		x"0000", x"FCB7", x"0000", x"03E1",
		x"0000", x"FB63", x"0000", x"058C",
		x"0000", x"F936", x"0000", x"088B",
		x"0000", x"F4C3", x"0000", x"1002",
		x"0000", x"E503", x"0000", x"516D",
		x"7FFF", x"516D", x"0000", x"E503",
		x"0000", x"1002", x"0000", x"F4C3",
		x"0000", x"088B", x"0000", x"F936",
		x"0000", x"058C", x"0000", x"FB63",
		x"0000", x"03E1", x"0000", x"FCB7",
		x"0000", x"02CB", x"0000", x"FD9F",
		x"0000", x"0207", x"0000", x"FE47",
		x"0000", x"0175", x"0000", x"FEC5",
		x"0000", x"0107", x"0000", x"FF26",
		x"0000", x"00B3", x"0000", x"FE68",
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
