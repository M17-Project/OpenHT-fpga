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
    generic(
        MAX_ADDR : natural := 20
    );
	port(
		miso_o	: out std_logic := 'Z';		                                -- serial data out
		mosi_i	: in std_logic;                                             -- serial data in
		sck_i	: in std_logic;				                                -- clock
		ncs_i	: in std_logic;			                                    -- slave select signal
		data_o	: out std_logic_vector(15 downto 0) := (others => '0'); 	-- received data register
		addr_o	: out std_logic_vector(13 downto 0) := (others => '0');		-- address
		data_i	: in std_logic_vector(15 downto 0);				            -- input data register
		nrst	: in std_logic;										    	-- reset
		ena		: in std_logic;						                        -- enable
		rw		: out std_logic := '0';							   		 	-- read/write flag, r=0, w=1
		ld      : out std_logic := '0';                                     -- load signal for a FIFO (positive pulse after word end)
		clk_i	: in std_logic										    	-- fast clock
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

	type spi_state_t is (ADDRESS, READ_REG, READ_REG2, DATA);
	signal spi_state : spi_state_t;
	signal addr_inc : std_logic := '0';

begin
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			-- Resync and edge detect
			csn_r <= csn_r(1 downto 0) & ncs_i;
			sck_r <= sck_r(1 downto 0) & sck_i;
			mosi_r <= mosi_r(1 downto 0) & mosi_i;

			din_valid <= '0';
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

				ld <= '0';
				case spi_state is
					when ADDRESS =>
						if din_valid then -- Triage valid data
							rw <= din_sreg(15);
							addr_inc <= din_sreg(14);
							addr_o <= din_sreg(13 downto 0);
							spi_state <= READ_REG;
						end if;

					when READ_REG =>
						spi_state <= READ_REG2;

					when READ_REG2 => -- TODO: remove this state after APB implementation
						spi_state <= DATA;
						dout_sreg <= data_i;

					when DATA =>
						if din_valid then -- Triage valid data
							if addr_inc then
								addr_o <= std_logic_vector(unsigned(addr_o) + 1);
							end if;
							data_o <= din_sreg;
							ld <= '1';
						end if;
				end case;
				miso_o <= dout_sreg(dout_sreg'high);

			else -- When slave is disabled
				din_sreg <= (others => '0');
				bit_cnt <= (others => '0');
				dout_sreg <= (others => '0');
				spi_state <= ADDRESS;
				miso_o <= 'Z';
			end if;

		end if;
	end process;
end magic;
