-------------------------------------------------------------
-- Decimating block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity decim is
	generic(
		DECIM		: integer := 10;
		BIT_SIZE	: integer := 16
	);
	port(
		clk_i					: in std_logic;											-- fast clock in
		i_data_i, q_data_i		: in signed(BIT_SIZE-1 downto 0);						-- data in
		i_data_o, q_data_o		: out signed(BIT_SIZE-1 downto 0) := (others => '0');	-- data out
		trig_i					: in std_logic;											-- trigger in
		drdy_o					: out std_logic := '0'									-- data ready out
	);
end decim;

architecture magic of decim is
	signal p_trig, pp_trig : std_logic := '0';
begin
	process(clk_i)
		variable counter : integer range 0 to DECIM+1 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			-- detect rising edge at the trig input
			if pp_trig='0' and p_trig='1' then
				drdy_o <= '0';
				counter := counter + 1;
			end if;

			if counter=DECIM then
				i_data_o <= i_data_i;
				q_data_o <= q_data_i;
				drdy_o <= '1';
				counter := 0;
			end if;
		end if;
	end process;
end magic;
