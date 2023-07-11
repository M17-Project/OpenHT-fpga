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
					data_o <= mac(2*SAMP_WIDTH-1 downto SAMP_WIDTH);
                    -- deassert busy flag
                    busy <= '0';
                end if;
            end if;
        end if;
	end process;

	drdy_o <= not busy;
end magic;
