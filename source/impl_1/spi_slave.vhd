--SPI slave
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
	port(
		mosi_i	: in std_logic;							-- serial data in
		sck_i	: in std_logic;							-- clock
		ncs_i	: in std_logic;							-- slave select signal
		data_o	: out std_logic_vector(31 downto 0);	-- data register
		nrst	: in std_logic;							-- reset
		ena		: in std_logic;							-- enable
		clk_i	: in std_logic							-- fast clock
	);
end spi_slave;

architecture magic of spi_slave is
	signal p_ncs, pp_ncs	: std_logic := '0';
	signal p_sck, pp_sck	: std_logic := '0';
	signal data_buff		: std_logic_vector(31 downto 0) := (others => '0');
begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			p_ncs <= ncs_i;
			pp_ncs <= p_ncs;
			p_sck <= sck_i;
			pp_sck <= p_sck;
			
			if ena='1' then
				-- falling edge of the nCS - data transaction start
				if ((pp_ncs='1' and p_ncs='0') or nrst='0') then
					data_buff <= (others => '0');
				end if;
				
				-- rising edge of SCK - data sampling if n_CS is low
				if (pp_sck='0' and p_sck='1' and ncs_i='0') then
					data_buff <= data_buff(30 downto 0) & mosi_i;
				end if;

				-- rising edge of nCS
				if (pp_ncs='0' and p_ncs='1') then
					data_o <= data_buff;
				end if;
			end if;
		end if;
	end process;
end magic;
