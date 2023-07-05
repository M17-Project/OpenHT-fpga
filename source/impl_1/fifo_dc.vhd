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
        DEPTH       : natural;  -- buffer length
        D_WIDTH     : natural   -- data width
    );
	port(
		wr_clk_i    : in std_logic;													-- write clock
        rd_clk_i    : in std_logic;													-- read clock
		--wr_en_i		: in std_logic;												-- write clock enable
		--rd_en_i		: in std_logic;												-- read clock enable
        data_i      : in std_logic_vector(D_WIDTH-1 downto 0);						-- input data
        data_o      : out std_logic_vector(D_WIDTH-1 downto 0) := (others => '0');	-- output data
        fifo_ae     : out std_logic := '1';											-- fifo almost empty (less than half)
		fifo_full	: out std_logic := '0';											-- fifo full			
		fifo_empty	: out std_logic := '1'											-- fifo empty
	);
end fifo_dc;

architecture magic of fifo_dc is
    type fifo_line is array(DEPTH-1 downto 0) of std_logic_vector(D_WIDTH-1 downto 0);
    signal fl : fifo_line := (others => (others => '0'));
	signal head, tail : unsigned(integer(ceil(log2(real(DEPTH+1)))) downto 0) := (others => '0');
	signal fill : unsigned(integer(ceil(log2(real(DEPTH+1)))) downto 0) := (others => '0');
	signal fifo_full_int : std_logic := '0';
	signal fifo_empty_int : std_logic := '1';
begin
	process(wr_clk_i)
	begin
		--if rising_edge(wr_clk_i) and wr_en_i='1' then
		if rising_edge(wr_clk_i) then
            fl <= fl(DEPTH-2 downto 0) & data_i;
            if fifo_full_int='0' then
                if head<DEPTH then
                    head <= head + 1;
                else
                    head <= (others => '0');
                end if;
			end if;
		end if;
	end process;

	process(rd_clk_i)
	begin
		--if rising_edge(rd_clk_i) and rd_en_i='1' then
		if rising_edge(rd_clk_i) then
            data_o <= fl(to_integer(head)-to_integer(tail)-1) when head>tail else
                fl(DEPTH-1-(to_integer(tail)-to_integer(head)-1)) when tail>head;
            if fifo_empty_int='0' then
                if tail<DEPTH then
                    tail <= tail + 1;
                else
                    tail <= (others => '0');
                end if;
			end if;
		end if;
	end process;

	-- combinational logic
	fifo_full_int <= '1' when head=tail-1 or (head=DEPTH and tail=0) else '0';
	fifo_empty_int <= '1' when tail=head else '0';
	fill <= head-tail when head>=tail else
        DEPTH-(tail-head-1) when tail>head;
	fifo_ae <= '1' when fill<DEPTH/2-1 else '0';
	
	fifo_full <= fifo_full_int;
	fifo_empty <= fifo_empty_int;
end magic;
