-------------------------------------------------------------
-- I/Q stream deserializer for the AT86RF215
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_des is
	port(
		clk_i		: in std_logic;						-- 64 MHz clock
		ddr_clk_i	: in std_logic;						-- DDR clock
		data_i		: in std_logic_vector(1 downto 0);
		nrst		: in std_logic;
		i_o, q_o	: out std_logic_vector(12 downto 0) := (others => '0');
		drdy		: out std_logic := '0'
	);
end iq_des;

architecture magic of iq_des is
	signal rx_r						: std_logic_vector(31 downto 0) := (others => '0');
	signal syncd					: std_logic := '0';
	signal drdy_int					: std_logic := '0';
	signal i_r, q_r					: std_logic_vector(12 downto 0) := (others => '0');
	signal i_o_pre0, i_o_pre1		: std_logic_vector(12 downto 0) := (others => '0');
	signal q_o_pre0, q_o_pre1		: std_logic_vector(12 downto 0) := (others => '0');
	signal drdy_pre0, drdy_pre1		: std_logic := '0';
begin
	process(ddr_clk_i)
		variable cnt : integer range 0 to 16+1 := 0;
		variable start_cnt : integer range 0 to 16+1 := 0;
	begin
		if rising_edge(ddr_clk_i) then
			if start_cnt<16 then -- discard some zero bits in the beginning
				start_cnt := start_cnt + 1;
			end if;
			
			if start_cnt=16 then
				if syncd='1' then
					rx_r <= rx_r(29 downto 0) & data_i(0) & data_i(1);
					cnt := cnt + 1;
				end if;
						
				-- I syncword is "10", but the DDR block reverses data order
				if data_i="01" and syncd='0' then
					syncd <= '1';
					rx_r <= rx_r(29 downto 0) & data_i(0) & data_i(1);
				end if;
				
				if cnt=16 then
					i_r <= rx_r(29 downto 17);
					q_r <= rx_r(13 downto 1);
					cnt := 0;
					drdy_int <= '1';
					syncd <= '0';
				end if;
						
				if cnt=1 then
					drdy_int <= '0';
				end if;
			end if;
			
			if nrst='0' then
				cnt := 0;
				start_cnt := 0;
				syncd <= '0';
				rx_r <= (others => '0');
				--i_o <= (others => '0');
				--q_o <= (others => '0');
				i_r <= (others => '0');
				q_r <= (others => '0');
			else
				i_o_pre0 <= i_r;
				q_o_pre0 <= q_r;
				drdy_pre0 <= drdy_int;
			end if;
		end if;
	end process;
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			i_o_pre1 <= i_o_pre0;
			q_o_pre1 <= q_o_pre0;
			drdy_pre1 <= drdy_pre0;
			
			i_o <= i_o_pre1;
			q_o <= q_o_pre1;
			drdy <= drdy_pre1;
		end if;
	end process;

	--process(clk_i, data_i, rst, syncd)
		--variable cnt : integer range 0 to 16+1 := 0;
		--variable start_cnt : integer range 0 to 16+1 := 0;
	--begin
		--if rising_edge(clk_i) then
			--p_ddr_clk <= ddr_clk_i;
			--pp_ddr_clk <= p_ddr_clk;
		
			--if rst='1' then
				--cnt := 0;
				--start_cnt := 0;
				--syncd <= '0';
				--rx_r <= (others => '0');
			--else
				--if pp_ddr_clk='0' and p_ddr_clk='1' then -- rising edge (??)
					--if start_cnt<16 then -- discard some zero bits in the beginning
						--start_cnt := start_cnt + 1;
					--end if;
					--if start_cnt=16 then
						--if syncd='1' then
							--rx_r <= rx_r(29 downto 0) & data_i(0) & data_i(1);
							--cnt := cnt + 1;
						--end if;
						
						---- I syncword is "10", but the DDR block reverses data order
						--if data_i="01" and syncd='0' then
							--syncd <= '1';
							--rx_r <= rx_r(29 downto 0) & data_i(0) & data_i(1);
						--end if;
						
						--if cnt=16 then
							--i_r <= rx_r(29 downto 17);
							--q_r <= rx_r(13 downto 1);
							--cnt := 0;
							--drdy <= '1';
							--syncd <= '0';
						--end if;
						
						--if cnt=1 then
							--drdy <= '0';
						--end if;
					--end if;
				--end if;
			--end if;
		--end if;
	--end process;
end magic;
