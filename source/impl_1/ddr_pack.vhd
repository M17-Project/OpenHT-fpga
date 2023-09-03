-------------------------------------------------------------
-- 2->32 bit packer for the AT86RF215
--
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- M17 Project
-- Aug 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;

entity ddr_pack is
	port(
		clk_i		: in std_logic;
		nrst_i   	: in std_logic;

		ddr_din : in std_logic_vector(1 downto 0);
		ddr_clkin : in std_logic;

		m_axis_iq_o : out axis_in_iq_t;
		m_axis_iq_i : in axis_out_iq_t
	);
end ddr_pack;

architecture magic of ddr_pack is

	signal ddr_data_locked : std_logic := '0';
	signal ddr_rx_reg : std_logic_vector(31 downto 0) := (others => '0');
	signal ddr_bit_cnt : unsigned(4 downto 0) := (others => '0');
	signal ddr_capture_reg : std_logic_vector(31 downto 0);
	signal ddr_capture_vld : std_logic := '0'; -- TOGGLE CDC

	signal data_valid_resync : std_logic_vector(2 downto 0);
begin

	-- DDR clock domain
	-- Crossing using a Toggle Synchronizer
	process (ddr_clkin)
	begin
		if rising_edge(ddr_clkin) then
			if ddr_data_locked then
				ddr_rx_reg <= ddr_rx_reg(29 downto 0) & ddr_din(0) & ddr_din(1);
				if ddr_bit_cnt < 15 then
					ddr_bit_cnt <= ddr_bit_cnt + 1;
				else
					if ddr_din /= "00" and ddr_din /= "01" then -- Lost SYNC, retry
						ddr_data_locked <= '0';
					end if;

					ddr_bit_cnt <= (others => '0');
					ddr_capture_reg <= ddr_rx_reg;
					ddr_capture_vld <= not ddr_capture_vld;

				end if;
			else -- Waiting for SYNC pattern
				if ddr_din = "01" then -- Found SYNC pattern
					ddr_data_locked <= '1';
					ddr_rx_reg <= X"00000002";
					ddr_bit_cnt <= (others => '0') ;
				end if;
			end if;
		end if;
	end process;

	-- 64 MHz clock domain
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if nrst_i = '0' then
				m_axis_iq_o.tvalid <= '0';
			else
				data_valid_resync <= data_valid_resync(1 downto 0) & ddr_capture_vld;
				if data_valid_resync(2) xor data_valid_resync(1) then
					if ddr_capture_reg(31 downto 30) = "10" then
						m_axis_iq_o.tvalid <= '1';
						if m_axis_iq_i.tready then -- Do not change data if not ready
							m_axis_iq_o.tdata(31 downto 16) <= ddr_capture_reg(29 downto 16) & "00";
							m_axis_iq_o.tdata(15 downto 0) <= ddr_capture_reg(13 downto 0) & "00";
						end if;
					end if;
				end if;

				if m_axis_iq_i.tready and m_axis_iq_o.tvalid then
					m_axis_iq_o.tvalid <= '0';
				end if;
			end if;
		end if;
	end process;
end magic;
