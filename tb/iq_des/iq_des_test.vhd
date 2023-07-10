--iq_des test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_des_test is
	--
end iq_des_test;

architecture sim of iq_des_test is
	component iq_des is
		port(
			clk_i		: in std_logic;
			data_i		: in std_logic_vector(1 downto 0);
			rst			: in std_logic;
			i_o, q_o	: out std_logic_vector(12 downto 0);
			drdy		: out std_logic
		);
	end component;

	signal clk_i		: std_logic := '0';
	signal data_i		: std_logic_vector(1 downto 0) := "00";
	signal rst			: std_logic := '0';
	signal i_o, q_o		: std_logic_vector(12 downto 0) := (others => '0');
	signal drdy			: std_logic := '0';
	signal src			: std_logic_vector(31 downto 0);
begin
	dut: iq_des port map(
		clk_i => clk_i,
		data_i => data_i,
		rst => '0',
		i_o => i_o,
		q_o => q_o,
		drdy => drdy
	);

	process
	begin
		src <= "01" & x"800"&"1" & "0" & "10" & x"000"&"0" & "0";
		wait for 0.95 ms;
		for i in 1 to 16 loop
			wait for 0.2 ms;
			src <= src(29 downto 0) & "00";
			data_i <= src(31 downto 30);
		end loop;
	end process;

	process
	begin
		clk_i <= not clk_i;
		wait for 0.1 ms;
	end process;
end sim;
