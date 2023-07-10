--SPI TX
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_tx is
	port(
		clk_i		: in std_logic;							-- clock in
		trig_i		: in std_logic;							-- data transfer trig in
		data_i		: in std_logic_vector(15 downto 0);		-- parallel data in
		ncs_o		: inout std_logic := '1';				-- chip select out
		data_o		: out std_logic := '0';					-- data out
		sck_o		: inout std_logic := '0'				-- data clock
	);
end spi_tx;

architecture magic of spi_tx is
	signal p_trig, pp_trig	: std_logic := '0';
	signal busy				: std_logic := '0';
	signal data_r			: std_logic_vector(15 downto 0) := (others => '0');
begin
	process(clk_i)
		variable cnt : integer range 0 to 32 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			-- detect rising edge at the trig input
			if pp_trig='0' and p_trig='1' then
				cnt := 0;
				data_r <= data_i;
				ncs_o <= '0';
			end if;

			if ncs_o='0' then
				if cnt=32 then
					ncs_o <= '1';
					cnt := 0;
					sck_o <= '0';
				else
					sck_o <= not sck_o;
					cnt := cnt + 1;
					if sck_o='1' then
						data_r <= data_r(14 downto 0) & "0";
						--report "cnt=" & to_string(14-(cnt-1)/2);
					end if;
				end if;
			end if;
		end if;
	end process;

	data_o <= data_r(15);
end magic;
