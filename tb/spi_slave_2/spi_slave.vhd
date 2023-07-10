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
    signal rx_r      : std_logic_vector(15 downto 0) := (others => '0');
    signal addr_incr : std_logic := '0';
begin
	process(sck_i, ncs_i)
		variable cnt    : natural := 0;
		variable offs   : natural := 0;
	begin
        if falling_edge(ncs_i) then
            cnt := 0;
            rx_r <= (others => '0');
        end if;

        if rising_edge(ncs_i) then
            rw <= '0';
            ld <= '0';
            miso_o <= 'Z';
        end if;

		if rising_edge(sck_i) then
            rx_r <= rx_r(14 downto 0) & mosi_i;
            if cnt=1 then
                rw <= rx_r(0) or rw;
                ld <= '0';
            end if;
            if cnt=2 then
                addr_incr <= rx_r(0);
            end if;
            if cnt=16-1 then
                addr_o <= std_logic_vector(unsigned(rx_r(12 downto 0) & mosi_i) + offs);
                offs := offs + 1;
            elsif cnt=32-1 then
                data_o <= rx_r(14 downto 0) & mosi_i;
                cnt := 15-1;
            end if;

            if rx_r(14)='0' then -- if read
                miso_o <= '0';
            end if;

            cnt := cnt + 1;
        end if;

        if falling_edge(sck_i) then
            if cnt=1 and rw='1' then
                ld <= '1';
            end if;
        end if;
	end process;
end magic;
