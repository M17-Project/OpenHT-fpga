-------------------------------------------------------------
-- RRC filter block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fir_rrc is
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
end fir_rrc;

architecture magic of fir_rrc is
	type fir_taps is array(integer range 0 to TAPS_NUM-1) of signed(15 downto 0);
	signal taps : fir_taps := (
		x"FFCC", x"FFD0", x"FFE0", x"FFFA",
		x"0019", x"0038", x"004E", x"0057",
		x"004F", x"0036", x"0010", x"FFE3",
		x"FFBB", x"FFA0", x"FF9B", x"FFB2",
		x"FFE4", x"002A", x"0076", x"00B8",
		x"00DC", x"00D1", x"008A", x"0007",
		x"FF50", x"FE7B", x"FDAA", x"FD06",
		x"FCBD", x"FCF8", x"FDDA", x"FF75",
		x"01C6", x"04B7", x"081C", x"0BB6",
		x"0F3D", x"1262", x"14DE", x"1675",
		x"1701", x"1675", x"14DE", x"1262",
		x"0F3D", x"0BB6", x"081C", x"04B7",
		x"01C6", x"FF75", x"FDDA", x"FCF8",
		x"FCBD", x"FD06", x"FDAA", x"FE7B",
		x"FF50", x"0007", x"008A", x"00D1",
		x"00DC", x"00B8", x"0076", x"002A",
		x"FFE4", x"FFB2", x"FF9B", x"FFA0",
		x"FFBB", x"FFE3", x"0010", x"0036",
		x"004F", x"0057", x"004E", x"0038",
		x"0019", x"FFFA", x"FFE0", x"FFD0",
		x"FFCC"
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
