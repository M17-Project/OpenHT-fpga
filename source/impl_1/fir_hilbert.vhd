-------------------------------------------------------------
-- Hilbert transformer block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fir_hilbert is
	generic(
		TAPS_NUM : integer := 81;
		SAMP_WIDTH	: integer := 16
	);
	port(
		clk_i		: in std_logic;									-- fast clock in
		data_i		: in signed(15 downto 0);						-- data in
		data_o		: out signed(15 downto 0) := (others => '0');	-- data out
		trig_i		: in std_logic;									-- trigger in
		drdy_o		: out std_logic := '0'							-- data ready out
	);
end fir_hilbert;

architecture magic of fir_hilbert is
	type fir_taps is array(integer range 0 to TAPS_NUM-1) of signed(15 downto 0);
	signal taps : fir_taps := (
		x"000F", x"FB5D", x"FFF5", x"FE7A",
		x"0000", x"FE39", x"0000", x"FDF0",
		x"0000", x"FD9E", x"0000", x"FD41",
		x"0000", x"FCD8", x"0000", x"FC5F",
		x"0000", x"FBD4", x"0000", x"FB31",
		x"0000", x"FA70", x"FFFF", x"F986",
		x"FFFF", x"F865", x"0001", x"F6F4",
		x"0000", x"F506", x"0000", x"F24B",
		x"0000", x"EE12", x"0001", x"E693",
		x"0000", x"D542", x"0000", x"8000",
		x"0000", x"7FFF", x"0000", x"2ABE",
		x"0000", x"196D", x"FFFF", x"11EE",
		x"0000", x"0DB5", x"0000", x"0AFA",
		x"0000", x"090C", x"FFFF", x"079B",
		x"0001", x"067A", x"0001", x"0590",
		x"0000", x"04CF", x"0000", x"042C",
		x"0000", x"03A1", x"0000", x"0328",
		x"0000", x"02BF", x"0000", x"0262",
		x"0000", x"0210", x"0000", x"01C7",
		x"0000", x"0186", x"000B", x"04A3",
		x"FFF1"
	);
	
	type delay_line is array(integer range 0 to TAPS_NUM-1) of signed(15 downto 0);
	signal dline : delay_line := (others => (others => '0'));

	signal busy : std_logic := '0';
	signal mac : signed(integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH-1 downto 0) := (others => '0');
	signal mul : signed(2*SAMP_WIDTH-1 downto 0) := (others => '0');
	signal cnt : integer range 0 to TAPS_NUM+1 := 0;
begin
	process(clk_i, trig_i)
	begin
        if rising_edge(trig_i) then
            -- update delay line
            dline <= dline(1 to TAPS_NUM-1) & data_i;
            -- init all stuff
            mul <= dline(0) * taps(0);
            mac <= (others => '0');
            cnt <= 0;
            busy <= '1';
        end if;

		if rising_edge(clk_i) then
            if busy='1' then
                if cnt<TAPS_NUM then
                    -- perform some arithmetic
                    mul <= dline(cnt) * taps(cnt);
                    mac <= mac + mul;
                    cnt <= cnt + 1;
                elsif cnt=TAPS_NUM then
                    -- output result
                    data_o <= mac(6+16+16-6-1 downto 6+16+16-6-1-16+1);
                    -- deassert busy flag
                    busy <= '0';
                end if;
            end if;
        end if;
	end process;

	drdy_o <= not busy;
end magic;
