--trig_test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity trig_test is
	port(
		clk_i       : in std_logic;
		trig_i      : in std_logic;
		data_i      : in std_logic_vector(15 downto 0);
		data_o      : out std_logic_vector(15 downto 0) := (others => '0');
		trig_o      : out std_logic := '0'
	);
end trig_test;

architecture magic of trig_test is
	signal p_trig       : std_logic_vector(1 downto 0) := (others => '0');
	signal data_pre     : std_logic_vector(15 downto 0) := (others => '0');
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
            p_trig <= p_trig(0 downto 0) & trig_i;
            data_o <= data_pre;
		end if;
	end process;

    -- combinational logic
	data_pre <= not data_i;

	-- trigger output update
	trig_o <= p_trig(1);
end magic;
