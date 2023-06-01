-------------------------------------------------------------
-- Serial FIR channel filter
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fir_channel is
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
end fir_channel;

architecture magic of fir_channel is
	type arr_sig_t is array(integer range 0 to TAPS_NUM-1) of signed(SAMP_WIDTH-1 downto 0);
	constant taps : arr_sig_t := (
		x"B125", x"F704", x"F6D9", x"F6E8",
		x"F73F", x"F7DD", x"F8CE", x"FA0C",
		x"FBA5", x"FD96", x"FFE6", x"028E",
		x"0592", x"08F4", x"0CAE", x"10B7",
		x"1515", x"19B4", x"1EA5", x"23BF",
		x"2916", x"2E99", x"343B", x"39EC",
		x"3FA8", x"455C", x"4B01", x"507C",
		x"55D5", x"5AF1", x"5FF2", x"646F",
		x"689B", x"6C7F", x"6FD9", x"72CE",
		x"7536", x"7728", x"7887", x"795F",
		x"79A3", x"795F", x"7887", x"7728",
		x"7536", x"72CE", x"6FD9", x"6C7F",
		x"689B", x"646F", x"5FF2", x"5AF1",
		x"55D5", x"507C", x"4B01", x"455C",
		x"3FA8", x"39EC", x"343B", x"2E99",
		x"2916", x"23BF", x"1EA5", x"19B4",
		x"1515", x"10B7", x"0CAE", x"08F4",
		x"0592", x"028E", x"FFE6", x"FD96",
		x"FBA5", x"FA0C", x"F8CE", x"F7DD",
		x"F73F", x"F6E8", x"F6D9", x"F704",
		x"B125"
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
