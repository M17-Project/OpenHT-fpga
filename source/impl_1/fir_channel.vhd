-------------------------------------------------------------
-- Serial FIR channel filter
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fir_channel is
	generic(
		TAPS_NUM : integer := 81
	);
	port(
		clk_i		: in std_logic;									-- fast clock in
		data_i		: in signed(15 downto 0);						-- data in
		data_o		: out signed(15 downto 0) := (others => '0');	-- data out
		trig_i		: in std_logic;									-- trigger in
		drdy_o		: out std_logic := '0'							-- data ready out
	);
end fir_channel;

architecture magic of fir_channel is
	type fir_taps is array(integer range 0 to TAPS_NUM-1) of signed(15 downto 0);
	signal taps : fir_taps := (
		--x"18B7", x"1EDE", x"2548", x"2BE5",
		--x"32A7", x"397D", x"4055", x"471D",
		--x"4DC3", x"5433", x"5A5D", x"602F",
		--x"6596", x"6A84", x"6EEA", x"72BA",
		--x"75E9", x"786E", x"7A40", x"7B5A",
		--x"7BB8", x"7B5A", x"7A40", x"786E",
		--x"75E9", x"72BA", x"6EEA", x"6A84",
		--x"6596", x"602F", x"5A5D", x"5433",
		--x"4DC3", x"471D", x"4055", x"397D",
		--x"32A7", x"2BE5", x"2548", x"1EDE",
		--x"18B7"
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
	
	type delay_line is array(integer range 0 to TAPS_NUM-1) of signed(15 downto 0);
	signal dline : delay_line := (others => (others => '0'));

	signal p_trig, pp_trig : std_logic := '0';
	signal busy : std_logic := '0';
	signal mac : signed(6+16+16-1 downto 0) := (others => '0');
	signal mul : signed(31 downto 0) := (others => '0');
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
				mac <= (others => '0');
				mul <= (others => '0');
				-- assert busy flag
				busy <= '1';
			end if;

			if busy='1' then
				if counter=TAPS_NUM-1 then
					-- output result
					data_o <= mac(6+16+16-6-1 downto 6+16+16-6-1-16+1);
					-- deassert busy flag
					busy <= '0';
					-- zero the counter and bring back shift registers to order
					counter := 0;
					--taps <= taps(TAPS_NUM-1) & taps(0 to TAPS_NUM-2);
					--dline <= dline(1 to TAPS_NUM-1) & dline(0);
				else
					-- perform some arithmetic
					mul <= dline(counter) * taps(counter);
					mac <= mac + mul;
					-- update shift registers
					--taps <= taps(TAPS_NUM-1) & taps(0 to TAPS_NUM-2);
					--dline <= dline(1 to TAPS_NUM-1) & dline(0);
					-- update the counter
					counter := counter + 1;
				end if;
			end if;
		end if;
	end process;

	drdy_o <= not busy;
end magic;
