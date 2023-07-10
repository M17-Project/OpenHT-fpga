--trig_test test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity trig_test_test is
	--
end trig_test_test;

architecture sim of trig_test_test is
	component trig_test is
		port(
            clk_i       : in std_logic;
            trig_i      : in std_logic;
            data_i      : in std_logic_vector(15 downto 0);
            data_o      : out std_logic_vector(15 downto 0);
            trig_o      : out std_logic
		);
	end component;

	signal clk_i    : std_logic := '0';
	signal trig_i   : std_logic := '0';
	signal trig_o   : std_logic := '0';
	signal data_i   : std_logic_vector(15 downto 0) := (others => '0');
	signal data_o   : std_logic_vector(15 downto 0);
begin
	dut: trig_test port map(
		clk_i => clk_i,
		trig_i => trig_i,
		data_i => data_i,
		data_o => data_o,
		trig_o => trig_o
	);

	process
	begin
        wait for 0.25 ms;
        data_i <= x"5555";
		wait for 0.2 ms;
		trig_i <= '1';
		wait for 0.7 ms;
		trig_i <= '0';
		wait for 0.55 ms;
	end process;

	process
	begin
		wait for 0.1 ms;
		clk_i <= not clk_i;
	end process;
end sim;
