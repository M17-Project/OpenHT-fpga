--iq_offset test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_offset_test is
	--
end iq_offset_test;

architecture sim of iq_offset_test is
	component iq_offset is
		port(
			i_i : in std_logic_vector(15 downto 0);
			q_i : in std_logic_vector(15 downto 0);
			ai_i : in std_logic_vector(15 downto 0);
			aq_i : in std_logic_vector(15 downto 0);
			i_o : out std_logic_vector(15 downto 0);
			q_o : out std_logic_vector(15 downto 0)
		);
	end component;

	signal i_i : std_logic_vector(15 downto 0) := x"FF00";
	signal q_i : std_logic_vector(15 downto 0) := x"FF00";
	signal ai_i : std_logic_vector(15 downto 0) := x"000A";
	signal aq_i : std_logic_vector(15 downto 0) := x"FFF6";
	signal i_o : std_logic_vector(15 downto 0) := (others => '0');
	signal q_o : std_logic_vector(15 downto 0) := (others => '0');
begin
	dut: iq_offset port map(
			i_i => i_i,
			q_i => q_i,
			ai_i => ai_i,
			aq_i => aq_i,
			i_o => i_o,
			q_o => q_o
	);

	process
	begin
		wait for 0.001 ms;
		i_i <= std_logic_vector(signed(i_i) + 1);
		q_i <= std_logic_vector(signed(q_i) + 1);
	end process;
end sim;
