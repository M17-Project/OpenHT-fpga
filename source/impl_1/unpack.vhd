-------------------------------------------------------------
-- 32->2 bit unpacker for the AT86RF215
-- with "zero words" insertion
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity unpack is
	port(
		clk_i	: in std_logic;
		zero	: in std_logic;						-- send zero words if high
		i_i		: in std_logic_vector(12 downto 0); -- 13-bit signed, sign at the MSB
		q_i		: in std_logic_vector(12 downto 0); -- 13-bit signed, sign at the MSB
		data_o	: out std_logic_vector(1 downto 0)
	);
end unpack;

architecture magic of unpack is
	signal tx_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
	process(clk_i)
		variable bit_cnt : integer range 0 to 32 := 0;
	begin
		if rising_edge(clk_i) then
			data_o <= tx_reg(30) & tx_reg(31); -- this is what the DDR block expects, i believe
		
			if bit_cnt=30 then
				if zero='0' then
					tx_reg <= "10" & i_i & "0" & "01" & q_i & "0";
				else
					tx_reg <= (others => '0');
				end if;
				bit_cnt := 0;
			else
				tx_reg <= tx_reg(29 downto 0) & "00";
				bit_cnt := bit_cnt + 2;
			end if;
		end if;
	end process;
end magic;
