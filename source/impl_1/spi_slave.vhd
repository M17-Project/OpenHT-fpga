-------------------------------------------------------------
-- SPI slave
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- March 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
	port(
		miso_o	: out std_logic := '0';									-- serial data out
		mosi_i	: in std_logic;											-- serial data in
		sck_i	: in std_logic;											-- clock
		ncs_i	: in std_logic;											-- slave select signal
		data_o	: out std_logic_vector(15 downto 0) := (others => '0');	-- received data register
		addr_o	: out std_logic_vector(14 downto 0) := (others => '0');	-- address (for data read)
		data_i	: in std_logic_vector(15 downto 0);						-- input data register
		nrst	: in std_logic;											-- reset
		ena		: in std_logic;											-- enable
		rw		: inout std_logic := '0';								-- read/write flag, r=0, w=1
		clk_i	: in std_logic											-- fast clock
	);
end spi_slave;

architecture magic of spi_slave is
	signal p_ncs, pp_ncs	: std_logic := '0';
	signal p_sck, pp_sck	: std_logic := '0';
	signal data_rx			: std_logic_vector(31 downto 0) := (others => '0');
	signal data_tx			: std_logic_vector(15 downto 0) := (others => '0');
begin
	process(clk_i)
		variable cnt : integer range 0 to 32 := 0;
	begin
		if rising_edge(clk_i) then
			p_ncs <= ncs_i;
			pp_ncs <= p_ncs;
			p_sck <= sck_i;
			pp_sck <= p_sck;
			
			if ena='1' then
				-- falling edge of the nCS - data transaction start
				if (pp_ncs='1' and p_ncs='0') or nrst='0' then
					data_rx <= (others => '0');
					miso_o <= '0';
					rw <= '0';
					cnt := 0;
				end if;
				
				-- rising edge of SCK - data sampling if n_CS is low
				if (pp_sck='0' and p_sck='1' and ncs_i='0') then
					data_rx <= data_rx(30 downto 0) & mosi_i;
					cnt := cnt + 1;
					if cnt=16 then
						addr_o <= data_rx(13 downto 0) & mosi_i;
					end if;
				end if;

				-- falling edge of SCK
				if (pp_sck='1' and p_sck='0' and ncs_i='0') then
					-- check if WRITE bit is set
					if cnt=16 then
						if data_rx(15)='1' then
							rw <= '1';
						else
							data_tx <= data_i(14 downto 0) & "0";
							miso_o <= data_i(15);
						end if;
					end if;

					-- if READ then clock out the data from data_tx
					if rw='0' and cnt>16 then
						data_tx <= data_tx(14 downto 0) & "0";
						miso_o <= data_tx(15);
					end if;

					-- latch data after the last received bit, in WRITE mode
					if cnt=32 then
						if rw='1' then
							data_o <= data_rx(15 downto 0);
						else
							miso_o <= '0';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
end magic;
