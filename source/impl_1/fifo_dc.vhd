-------------------------------------------------------------
-- Dual clock FIFO
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fifo_dc is
    generic(
        DEPTH       : natural := 32;			-- buffer length
        D_WIDTH     : natural := 32;			-- data width
		AE_THRESH	: natural := DEPTH/2-1;		-- almost empty threshold
		AF_THRESH	: natural := DEPTH/2-1		-- almost full threshold
    );
	port(
		clk_i			: in std_logic;													-- fast clock in
		nrst_i			: in std_logic;													-- nRST input
		wr_clk_i		: in std_logic;													-- write clock
        rd_clk_i		: in std_logic;													-- read clock
		wr_en_i			: in std_logic;													-- write clock enable
		rd_en_i			: in std_logic;													-- read clock enable
        wr_data_i      	: in std_logic_vector(D_WIDTH-1 downto 0);						-- input data
        rd_data_o      	: out std_logic_vector(D_WIDTH-1 downto 0) := (others => '0');	-- output data
		fifo_empty_o	: out std_logic := '1';											-- fifo empty
        fifo_ae_o     	: out std_logic := '1';											-- fifo almost empty (fill < threshold)
		fifo_af_o     	: out std_logic := '0';											-- fifo almost full (fill > threshold)
		fifo_full_o		: out std_logic := '0'											-- fifo full			
	);
end fifo_dc;

architecture magic of fifo_dc is
    type fifo_line is array(DEPTH-1 downto 0) of std_logic_vector(D_WIDTH-1 downto 0);
    signal fl : fifo_line := (others => (others => '0'));
	signal head, tail : unsigned(integer(ceil(log2(real(DEPTH+1)))) downto 0) := (others => '0');
	signal fill : unsigned(integer(ceil(log2(real(DEPTH+1)))) downto 0) := (others => '0');
	signal fifo_full_int : std_logic := '0';
	signal fifo_empty_int : std_logic := '1';
	
	signal p_wr_clk, pp_wr_clk : std_logic := '0';
	signal p_rd_clk, pp_rd_clk : std_logic := '0';
begin
	process(clk_i, nrst_i)
	begin
		if nrst_i='1' then
			if rising_edge(clk_i) then
				-- push clocks
				p_wr_clk <= wr_clk_i;
				pp_wr_clk <= p_wr_clk;
				p_rd_clk <= rd_clk_i;
				pp_rd_clk <= p_rd_clk;		
			
				-- if rising edge of wr_clk_i and write enable
				if pp_wr_clk='0' and p_wr_clk='1' and wr_en_i='1' then
					fl <= fl(DEPTH-2 downto 0) & wr_data_i;
					if fifo_full_int='0' then
						if head<DEPTH then
							head <= head + 1;
						else
							head <= (others => '0');
						end if;
					end if;
				end if;

				-- if rising edge of rd_clk_i and read enable
				if pp_rd_clk='0' and p_rd_clk='1' and rd_en_i='1' then
					rd_data_o <= fl(to_integer(head)-to_integer(tail)-1) when head>tail else
						fl(DEPTH-1-(to_integer(tail)-to_integer(head)-1)) when tail>head;
					if fifo_empty_int='0' then
						if tail<DEPTH then
							tail <= tail + 1;
						else
							tail <= (others => '0');
						end if;
					end if;
				end if;
			end if;
		else
			head <= (others => '0');
			tail <= (others => '0');
			fl <= (others => (others => '0'));
		end if;
	end process;

	-- combinational logic
	fifo_full_int	<= '1' when head=tail-1 or (head=DEPTH and tail=0) else '0';
	fifo_empty_int	<= '1' when tail=head else '0';
	fill			<= head-tail when head>=tail else
        DEPTH-(tail-head-1) when tail>head;
		
	fifo_empty_o	<= fifo_empty_int;
	fifo_ae_o		<= '1' when fill<AE_THRESH else '0';
	fifo_af_o		<= '1' when fill>AF_THRESH else '0';
	fifo_full_o		<= fifo_full_int;
end magic;
