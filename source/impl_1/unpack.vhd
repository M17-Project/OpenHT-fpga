-------------------------------------------------------------
-- 32->2 bit unpacker for the AT86RF215
--
-- Wojciech Kaczmarski, SP5WWP
-- Sebastien Van Cauwenberghe, ON4SEB
-- 
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;

entity unpack is
	port(
		clk_i		: in std_logic;
		nrst_i   	: in std_logic;
		s_axis_iq_i : in axis_in_iq_t;
		s_axis_iq_o : out axis_out_iq_t := (others => '0');
		data_o		: out std_logic_vector(1 downto 0) := (others => '0')
	);
end unpack;

architecture magic of unpack is
    component tx_out_fifo
        port (
			clk_i : in std_logic;
			nrst_i : in std_logic;
			wr_en_i : in std_logic;
			rd_en_i : in std_logic;
			wr_data_i : in std_logic_vector (32 downto 0);
			full_o : out std_logic;
			empty_o : out std_logic;
			rd_data_o : out std_logic_vector (32 downto 0)
		);
    end component;

	signal wr_en_i : std_logic := '0';
    signal full_o : std_logic := '0';
    signal empty_o : std_logic := '0';
    signal wr_data_i : std_logic_vector (32 downto 0) := (others => '0');

	signal rd_data_o : std_logic_vector (32 downto 0) := (others => '0');
	signal rd_en_i : std_logic := '0';

	type unpack_state_t is (IDLE, DATA, PADDING);
	signal unpack_state: unpack_state_t := PADDING;
	signal next_tx_reg : std_logic_vector(31 downto 0) := (others => '0');

	signal sreg_reload : std_logic := '0';
	signal pad_count : unsigned(3 downto 0) := (others => '0');
	signal tx_reg : std_logic_vector(31 downto 0) := (others => '0');
	signal bit_cnt : unsigned(4 downto 0) := (others => '0');
begin
	sreg_reload <= '1' when bit_cnt >= 15 else '0';

	wr_en_i <= s_axis_iq_i.tvalid and not full_o;
	s_axis_iq_o.tready <= not full_o;
	wr_data_i <= s_axis_iq_i.tlast & s_axis_iq_i.tdata;

	tx_out_fifo_inst : entity work.fifo_dc
	generic map(
        DEPTH => 32,
        D_WIDTH => 33		
	)
	port map(
		clk_i => clk_i,
		nrst_i => nrst_i,
		wr_en_i => wr_en_i,
		rd_en_i => rd_en_i,
		wr_data_i => wr_data_i,
		fifo_full_o => full_o,
		fifo_empty_o => empty_o,
		rd_data_o => rd_data_o
	);
	--rd_data_o <= s_axis_iq_i.tlast & s_axis_iq_i.tdata;

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			data_o <= tx_reg(30) & tx_reg(31); -- this is what the DDR block expects, i believe
			rd_en_i <= '0';

			-- Decide what is next data to shift
			case unpack_state is
				when DATA =>
					next_tx_reg <= "10" & rd_data_o(31 downto 19) & "0" & "01" & rd_data_o(15 downto 3) & "0";
					if sreg_reload then
						unpack_state <= PADDING;
						pad_count <= (others => '0');
						rd_en_i <= '1'; -- Data will be out of the FIFO for the next round after padding
					end if;

				when PADDING =>
					next_tx_reg <= (others => '0');
					if sreg_reload then
						if pad_count = 8 then
							unpack_state <= DATA;
							pad_count <= (others => '0');
						else
							pad_count <= pad_count + 1;
						end if;
					end if;

				when others => -- IDLE
					next_tx_reg <= (others => '0');
					unpack_state <= DATA;
			end case;

			if not sreg_reload then
				bit_cnt <= bit_cnt + 1;
				tx_reg <= tx_reg(29 downto 0) & "00";
			else
				bit_cnt <= (others => '0');
				tx_reg <= next_tx_reg;
			end if;

		end if;
	end process;
end magic;
