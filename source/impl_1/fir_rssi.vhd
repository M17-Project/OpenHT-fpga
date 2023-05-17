-------------------------------------------------------------
-- RSSI estimator FIR filter
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- May 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fir_rssi is
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
end fir_rssi;

architecture magic of fir_rssi is
	-- filter taps were generated with
	-- firpm(n, [0, f1, f2, 1], [1, 1, 0, 0])
	-- where
	-- f1=20/1500/2;   %pass band edge, 1500 ~= 400e3/(2^8)
	-- f2=160/1500/2;  %stop band edge
	-- then normalized to unity gain at DC and multiplied by 4
	-- to be finally converted to a signed int16, 0x4000=+1.0
	type fir_taps is array(integer range 0 to TAPS_NUM-1) of signed(15 downto 0);
	signal taps : fir_taps := (
		x"FE07", x"FFD3", x"FFD5", x"FFDB",
		x"FFE4", x"FFF2", x"0003", x"0019",
		x"0034", x"0053", x"0077", x"00A0",
		x"00CE", x"0101", x"0138", x"0175",
		x"01B5", x"01FA", x"0242", x"028E",
		x"02DD", x"032E", x"0380", x"03D4",
		x"0428", x"047C", x"04CF", x"0520",
		x"056F", x"05BB", x"0603", x"0645",
		x"0684", x"06BC", x"06EE", x"071A",
		x"073E", x"075A", x"076F", x"077B",
		x"077F", x"077B", x"076F", x"075A",
		x"073E", x"071A", x"06EE", x"06BC",
		x"0684", x"0645", x"0603", x"05BB",
		x"056F", x"0520", x"04CF", x"047C",
		x"0428", x"03D4", x"0380", x"032E",
		x"02DD", x"028E", x"0242", x"01FA",
		x"01B5", x"0175", x"0138", x"0101",
		x"00CE", x"00A0", x"0077", x"0053",
		x"0034", x"0019", x"0003", x"FFF2",
		x"FFE4", x"FFDB", x"FFD5", x"FFD3",
		x"FE07"
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
