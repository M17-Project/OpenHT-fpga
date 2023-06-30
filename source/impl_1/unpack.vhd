-------------------------------------------------------------
-- 32->2 bit unpacker for the AT86RF215
-- with "zero words" insertion
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity unpack is
	port(
		clk_i	: in std_logic;
		i_i		: in std_logic_vector(15 downto 0);						-- 16-bit signed, sign at the MSB
		q_i		: in std_logic_vector(15 downto 0);						-- 16-bit signed, sign at the MSB
		req_o	: out std_logic := '0';									-- data request
		data_o	: out std_logic_vector(1 downto 0) := (others => '0')	-- dibit data out for DDR
	);
end unpack;

architecture magic of unpack is
	signal tx_reg : std_logic_vector(31 downto 0) := (others => '0');
	signal req : std_logic := '0';
begin
	process(clk_i)
		variable cnt : natural range 0 to 160 := 0;
	begin
		if rising_edge(clk_i) then
			data_o <= tx_reg(30) & tx_reg(31); -- this is what the DDR block expects, i believe

			if cnt=160 then
				tx_reg <= "10" & i_i(15 downto 3) & "0" & "01" & q_i(15 downto 3) & "0"; -- latch data
				req <= '0';
				cnt := 0;
			else
                tx_reg <= tx_reg(29 downto 0) & "00";
                req <= '1';
				cnt := cnt + 1;
			end if;
		end if;
	end process;
	
	req_o <= req;
end magic;
