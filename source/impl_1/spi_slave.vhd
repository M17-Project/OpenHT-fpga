-------------------------------------------------------------
-- SPI slave
--
-- Wojciech Kaczmarski, SP5WWP
-- Sébastien, ON4SEB
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
	port(
		clk_i	: in std_logic;  									    	-- fast clock

		miso_o	: out std_logic := 'Z';		                                -- serial data out
		mosi_i	: in std_logic;                                             -- serial data in
		sck_i	: in std_logic;				                                -- clock
		ncs_i	: in std_logic;			                                    -- slave select signal

		dout_o	: out std_logic_vector(15 downto 0) := (others => '0'); 	-- received data register
		dout_vld_o : out std_logic;                                         -- Output data valid
		cs_o    : out std_logic;                                            -- Chip select
		din_i	: in std_logic_vector(15 downto 0);				            -- input data register
		din_vld_i: in std_logic                 				            -- input data register valid
	);
end spi_slave;

architecture magic of spi_slave is
	-- Resync registers
	signal csn_r : std_logic_vector(2 downto 0);
	signal sck_r : std_logic_vector(2 downto 0);
	signal mosi_r : std_logic_vector(2 downto 0);

	-- State registers
	signal din_sreg : std_logic_vector(15 downto 0);
	signal din_valid : std_logic;
	signal dout_sreg : std_logic_vector(15 downto 0);
	signal bit_cnt : unsigned(4 downto 0);

begin
	miso_o <= 'Z' when ncs_i = '1' else dout_sreg(dout_sreg'high);

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			-- Resync and edge detect
			csn_r <= csn_r(1 downto 0) & ncs_i;
			sck_r <= sck_r(1 downto 0) & sck_i;
			mosi_r <= mosi_r(1 downto 0) & mosi_i;

			din_valid <= '0';
			cs_o <= not csn_r(1);
			if not csn_r(1) then
				-- Capture data on rising edge, output it every 16 clock cycles
				if not sck_r(2) and sck_r(1) then
					-- Input part
					din_sreg <= din_sreg(14 downto 0) & mosi_r(1);
					bit_cnt <= bit_cnt + 1;
					if bit_cnt = 15 then -- 1 full word captured
						bit_cnt <= (others => '0');
						din_valid <= '1';
					end if;

					-- Output part
					-- Updating output on the rising edge makes it appear more or less at the falling edge
					-- This should respect setup/hold wrt to rising edge
					dout_sreg <= dout_sreg(14 downto 0) & '0';

				end if;

				-- Load output SREG
				if din_vld_i then
					dout_sreg <= din_i(7 downto 0) & din_i(15 downto 8);
				end if;

				-- Serial input SREG
				if din_valid then
					dout_o <= din_sreg(7 downto 0) & din_sreg(15 downto 8);
				end if;
				dout_vld_o <= din_valid;

			else -- When slave is disabled
				din_sreg <= (others => '0');
				bit_cnt <= (others => '0');
				dout_sreg <= (others => '0');

			end if;

		end if;
	end process;
end magic;
