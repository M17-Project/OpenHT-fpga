-------------------------------------------------------------
-- SPI slave
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
    generic(
        MAX_ADDR : natural := 20
    );
	port(
		miso_o	: out std_logic := 'Z';		                                -- serial data out
		mosi_i	: in std_logic;                                             -- serial data in
		sck_i	: in std_logic;				                                -- clock
		ncs_i	: in std_logic;			                                    -- slave select signal
		data_o	: out std_logic_vector(15 downto 0) := (others => '0'); 	-- received data register
		addr_o	: inout std_logic_vector(13 downto 0) := (others => '0');	-- address
		data_i	: in std_logic_vector(15 downto 0);				            -- input data register
		nrst	: in std_logic;										    	-- reset
		ena		: in std_logic;						                        -- enable
		rw		: inout std_logic := '0';							    	-- read/write flag, r=0, w=1
		ld      : out std_logic := '0';                                     -- load signal for a FIFO (positive pulse after word end)
		clk_i	: in std_logic										    	-- fast clock
	);
end spi_slave;

architecture magic of spi_slave is
	signal p_ncs, pp_ncs	: std_logic := '0';
	signal p_sck, pp_sck	: std_logic := '0';
	signal data_rx			: std_logic_vector(31 downto 0) := (others => '0');
	signal data_tx			: std_logic_vector(15 downto 0) := (others => '0');
	signal addr_inc         : std_logic := '0';
	signal got_data			: std_logic := '0';
begin
	process(clk_i)
		variable cnt    : integer range 0 to 32 := 0;
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
					ld <= '0';
					rw <= '0';
					got_data <= '0';
					cnt := 0;
				end if;

				-- rising edge of SCK - data sampling if n_CS is low
				if (pp_sck='0' and p_sck='1' and ncs_i='0') then
					data_rx <= data_rx(30 downto 0) & mosi_i;
					cnt := cnt + 1;
					if cnt=16 then -- if it's the last bit
						addr_o <= data_rx(12 downto 0) & mosi_i;
					end if;
					if cnt=17 then
                        ld <= '0';
                        if addr_inc='1' then
                            if unsigned(addr_o)<MAX_ADDR then
                                addr_o <= std_logic_vector(unsigned(addr_o) + 1);
                            else
                                addr_o <= (others => '0');
                            end if;
						end if;
                    end if;
				end if;

				-- falling edge of SCK
				if (pp_sck='1' and p_sck='0' and ncs_i='0') then
					-- check if WRITE bit is set
					if cnt=16 then
						if data_rx(15)='1' then
							if got_data='0' then
								rw <= '1';
							end if;
						else
							data_tx <= data_i(14 downto 0) & "0";
							miso_o <= data_i(15);
						end if;
					end if;

					if cnt=24 and got_data='0' then -- in the middle of the data
                        if data_rx(22)='1' then
                            addr_inc <= '1'; -- update the address increment flag
                        end if;
					end if;

					-- if READ then clock out the data from data_tx
					if rw='0' and cnt>16 then
						data_tx <= data_tx(14 downto 0) & "0";
						miso_o <= data_tx(15);
					end if;

					-- last clock - falling edge
					if cnt=32 then
						if rw='1' then -- write - latch data
							data_o <= data_rx(15 downto 0);
						else -- read - deassert MISO line
							miso_o <= '0';
						end if;
						cnt := 16;
						if rw='1' then
                            --
						else
                            data_tx <= data_i(14 downto 0) & "0";
							miso_o <= data_i(15);
						end if;
						ld <= '1';
						got_data <= '1';
					end if;
				end if;

                -- rising edge of the nCS - data transaction stop
				if (pp_ncs='0' and p_ncs='1') or nrst='0' then
					miso_o <= 'Z';
					addr_inc <= '0'; -- reset the address increment flag
					got_data <= '0';
					ld <= '0'; -- release the ld line
					rw <= '0'; -- release the RW flag
				end if;
			end if;
		end if;
	end process;
end magic;
