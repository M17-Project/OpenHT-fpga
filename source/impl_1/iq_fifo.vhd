-------------------------------------------------------------
-- IQ FIFO block
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity iq_fifo is
	generic(
		DEPTH					: natural := 8;
		D_WIDTH					: natural := 16
	);
	port(
		clk_i					: in std_logic;													-- clock in
		nrst_i					: in std_logic;													-- nRST in
		trig_i					: in std_logic;													-- trigger in
		wr_clk_i				: in std_logic;													-- write clock
		rd_clk_i				: in std_logic;													-- read clock
		i_i, q_i				: in std_logic_vector(D_WIDTH-1 downto 0);						-- trigger in
		i_o, q_o				: out std_logic_vector(D_WIDTH-1 downto 0) := (others => '0')	-- data ready out
	);
end iq_fifo;

architecture magic of iq_fifo is
	signal out_rdy			: std_logic := '0';
	signal i_out_ae			: std_logic := '0';
	signal q_out_ae			: std_logic := '0';
	signal wr_clk_en		: std_logic := '0';
	signal i_out, q_out		: std_logic_vector(D_WIDTH-1 downto 0) := (others => '0');
begin
	out_rdy <= (not i_out_ae) and (not q_out_ae);
	
	--process(clk_i)
	--begin
		--if rising_edge(clk_i) then
			i_o <= i_out;
			q_o <= q_out;
		--end if;
	--end process;
	
	process(trig_i, out_rdy)
	begin
		if nrst_i='1' then
			if rising_edge(out_rdy) then
				wr_clk_en <= '1';
			end if;
		else
			wr_clk_en <= '0';
		end if;
	end process;
	
	i_fifo: entity work.fifo_dc generic map(
		DEPTH => DEPTH,
		D_WIDTH => D_WIDTH
	)
	port map(
		clk_i => clk_i,
		nrst_i => nrst_i,
		wr_clk_i => trig_i,
        rd_clk_i => trig_i and wr_clk_en,
        wr_data_i => i_i,
        rd_data_o => i_out,
		fifo_empty_o => open,
        fifo_ae_o => i_out_ae,
		fifo_af_o => open,
		fifo_full_o => open
	);
	
	q_fifo: entity work.fifo_dc generic map(
		DEPTH => DEPTH,
		D_WIDTH => D_WIDTH
	)
	port map(
		clk_i => clk_i,
		nrst_i => nrst_i,
		wr_clk_i => trig_i,
        rd_clk_i => trig_i and wr_clk_en,
        wr_data_i => q_i,
        rd_data_o => q_out,
		fifo_empty_o => open,
        fifo_ae_o => q_out_ae,
		fifo_af_o => open,
		fifo_full_o => open
	);
end magic;