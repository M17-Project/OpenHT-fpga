-------------------------------------------------------------
-- Generic serial FIR filter
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- TODO: expand the data length from 13 to 16 bits
entity fir_serial is
	generic(
		TAPS_NUM : integer := 31
	);
	port(
		clk_i		: in std_logic;									-- fast clock in
		data_i		: in signed(12 downto 0);						-- data in
		data_o		: out signed(12 downto 0) := (others => '0');	-- data out
		trig_i		: in std_logic;									-- trigger in
		drdy_o		: out std_logic := '0'							-- data ready out
	);
end fir_serial;

architecture magic of fir_serial is
	type fir_taps is array(integer range 0 to TAPS_NUM-1) of signed(15 downto 0);
	constant taps : fir_taps := (
		x"FF01", x"FF73", x"FF69", x"FF78",
		x"FFA8", x"FFFD", x"0078", x"0119",
		x"01D7", x"02AA", x"0383", x"0453",
		x"0509", x"0598", x"05F2", x"0611",
		x"05F2", x"0598", x"0509", x"0453",
		x"0383", x"02AA", x"01D7", x"0119",
		x"0078", x"FFFD", x"FFA8", x"FF78",
		x"FF69", x"FF73", x"FF01"
	);
	
	type delay_line is array(integer range 0 to TAPS_NUM-1) of signed(12 downto 0);
	signal dline : delay_line := (others => (others => '0'));

	signal p_trig, pp_trig : std_logic := '0';
	signal busy : std_logic := '0';
	signal mac : signed(5+13+16-1 downto 0) := (others => '0');
begin
	process(clk_i)
		variable counter : integer range 0 to TAPS_NUM+1 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			-- detect rising edge at the trig input
			if pp_trig='0' and p_trig='1' then
				counter := 0;
				dline <= dline(1 to TAPS_NUM-1) & data_i;
				mac <= (others => '0');
				busy <= '1';
			end if;

			if busy='1' then
				if counter=TAPS_NUM then
					counter := 0;
					busy <= '0';
					data_o <= mac(33-7 downto 21-7);
				else
					mac <= mac + dline(counter) * taps(TAPS_NUM-counter-1);
					counter := counter + 1;
				end if;
			end if;
		end if;
	end process;

	drdy_o <= not busy;
end magic;
