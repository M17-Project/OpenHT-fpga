-- IQ deserializer for the AT86RF215
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_des is
	port(
		clk_i		: in std_logic;
		data_i		: in std_logic_vector(1 downto 0);
		rst			: in std_logic;
		i_o, q_o	: out std_logic_vector(12 downto 0) := (others => '0');
		drdy		: out std_logic := '0'
	);
end iq_des;

architecture magic of iq_des is
	signal rx_r		: std_logic_vector(31 downto 0) := (others => '0');
	signal syncd	: std_logic := '0';
	signal i_r, q_r	: std_logic_vector(12 downto 0) := (others => '0');
begin
	process(clk_i)
		variable cnt : integer range 0 to 16 := 0;
	begin
		if rising_edge(clk_i) then
			if rst='1' then
				cnt := 0;
				syncd <= '0';
				rx_r <= (others => '0');
			else
				if syncd='1' then
					rx_r <= rx_r(29 downto 0) & data_i;
					cnt := cnt + 1;
				end if;
				
				-- I syncword is "01", but DDR block reverses data order
				if data_i="01" and syncd='0' then
					syncd <= '1';
					rx_r <= rx_r(29 downto 0) & data_i;
				end if;
				
				if cnt=16 then
					i_r <= rx_r(29 downto 17);
					q_r <= rx_r(13 downto 1);
					cnt := 0;
					drdy <= '1';
					syncd <= '0';
				end if;
				
				if cnt=1 then
					drdy <= '0';
				end if;
			end if;
		end if;
	end process;

	i_o <= i_r;
	q_o <= q_r;
end magic;
