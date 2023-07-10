--serial FIR filter test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity serial_fir_test is
	--
end serial_fir_test;

architecture sim of serial_fir_test is
	component serial_fir is
		port(
			clk_i		: in std_logic;									-- fast clock in
			data_i		: in signed(15 downto 0);						-- data in
			data_o		: out signed(15 downto 0);						-- data out
			trig_i		: in std_logic;									-- trigger in
			drdy_o		: out std_logic := '0'							-- data ready out
		);
	end component;

	signal clk_i		: std_logic := '0';
	signal data_i		: signed(15 downto 0) := (others => '0');
	signal trig_i		: std_logic := '0';
	signal data_o		: signed(15 downto 0) := (others => '0');
	signal drdy_o		: std_logic := '0';
begin
	dut: serial_fir port map(clk_i => clk_i, data_i => data_i, trig_i => trig_i,
		data_o => data_o, drdy_o => drdy_o);

	process
		--
	begin
		wait for 2 ms;
		data_i <= x"4000";
	end process;

	process
	begin
		wait for 40 us;
		trig_i <= '1';
		wait for 5 us;
		trig_i <= '0';
	end process;

	process
	begin
		clk_i <= not clk_i;
		wait for 1.0 us;
	end process;
end sim;
