-------------------------------------------------------------
-- RSSI estimator
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- May 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity rssi_est is
	generic(
		NUM		: integer := 2**8
	);
	port(
		clk_i	: in std_logic;
		r_i		: in signed(15 downto 0);
		r_o		: out unsigned(15 downto 0) := (others => '0');
		rdy		: out std_logic := '0'
	);
end rssi_est;

architecture magic of rssi_est is
	signal sum : unsigned(integer(ceil(log2(real(NUM))))+15 downto 0) := (others => '0');
begin
	process(clk_i)
		variable cnt : integer := 0;
	begin
		if rising_edge(clk_i) then
			sum <= sum + unsigned(-r_i) when r_i<0 else sum + unsigned(r_i);
			cnt := cnt + 1;

			if cnt=NUM then
				cnt := 0;
				r_o <= sum(sum'left downto sum'left-15);
				sum <= resize(unsigned(-r_i), sum'left+1) when r_i<0 else resize(unsigned(r_i), sum'left+1);
			end if;
			
			--TODO: add a rdy_o signal
			if cnt=1 then
				rdy <= '1';
			end if;
			if cnt=NUM/2+1 then
				rdy <= '0';
			end if;
		end if;
	end process;
end magic;
