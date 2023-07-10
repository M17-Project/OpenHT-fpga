-------------------------------------------------------------
-- SPI slave
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
    generic(
        MAX_ADDR : natural := 20
    );
	port(
        clk_i	: in std_logic;										    	-- fast clock
		miso_o	: out std_logic := 'Z';		                                -- serial data out
		mosi_i	: in std_logic;                                             -- serial data in
		sck_i	: in std_logic;				                                -- clock
		ncs_i	: in std_logic;			                                    -- slave select signal
		data_o	: out std_logic_vector(15 downto 0) := (others => '0'); 	-- received data register
		addr_o	: inout std_logic_vector(13 downto 0) := (others => '0');	-- address
		data_i	: in std_logic_vector(15 downto 0);				            -- input data register
		nrst	: in std_logic;										    	-- reset
		ena		: in std_logic;						                        -- enable
		rw		: out std_logic := '0';							        	-- read/write flag, r=0, w=1
		ld      : out std_logic := '0'                                      -- load signal for a FIFO (positive pulse after word end)
	);
end spi_slave;

architecture magic of spi_slave is
	signal addr_rx			: std_logic_vector(15 downto 0) := (others => '0');
	signal data_rx			: std_logic_vector(15 downto 0) := (others => '0');
	signal data_tx			: std_logic_vector(15 downto 0) := (others => '0');
	signal cnt              : unsigned(5 downto 0) := (others => '0');
	signal addr_inc         : std_logic := '0';
	signal got_addr         : std_logic := '0';
	signal got_data         : std_logic := '0';
begin
	process(sck_i, ncs_i)
		--variable cnt    : integer := 0;
	begin
        if ncs_i='0' then
            if rising_edge(sck_i) then
                -- bit counter update
                if cnt<32-1 then
                    cnt <= cnt + 1;
                else
                    cnt <= to_unsigned(16, 6);
                    got_data <= '1';

                    -- latch data out
                    if rw='1' then
                        data_o <= data_rx(14 downto 0) & mosi_i;
                    else
                        --
                    end if;

                    -- autoincrement?
                    if addr_inc='1' and got_data='1' then
                        -- wrap around
                        if unsigned(addr_o)<MAX_ADDR then
                            addr_o <= std_logic_vector(unsigned(addr_o) + 1);
                        else
                            addr_o <= (others => '0');
                        end if;
                    end if;
                end if;

                -- push address
                if cnt<16 and got_addr='0' then
                    addr_rx <= addr_rx(14 downto 0) & mosi_i;
                end if;

                -- retrieve RW bit
                if cnt=0 then
                    rw <= mosi_i;
                end if;

                -- retrieve ADDR_INCR bit
                if cnt=1 then
                    addr_inc <= mosi_i;
                end if;

                if cnt=15 and got_addr='0' then
                    addr_o <= addr_rx(12 downto 0) & mosi_i;
                    got_addr <= '1';
                end if;

                if cnt>15 then
                    data_rx <= data_rx(14 downto 0) & mosi_i;
                end if;


            end if;

            if falling_edge(sck_i) then
                -- register readout
                if cnt>15 and rw='0' then
                    miso_o <= data_i(31-to_integer(cnt));
                end if;

                -- load strobe
                if got_data='1' then
                    if cnt=16 then
                        ld <= '1';
                    else
                        ld <= '0';
                    end if;
                end if;
            end if;
        else
            cnt <= (others => '0');
            addr_rx <= (others => '0');
            data_rx <= (others => '0');
            got_addr <= '0';
            got_data <= '0';
            ld <= '0';
            miso_o <= 'Z';
        end if;
	end process;
end magic;
