-------------------------------------------------------------
-- Dual clock FIFO
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
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
		en_i		: in std_logic;
		clk_a_i     : in std_logic;
        clk_b_i     : in std_logic;
        data_i      : in std_logic_vector(D_WIDTH-1 downto 0);
        data_o      : out std_logic_vector(D_WIDTH-1 downto 0) := (others => '0');
        fifo_ae     : out std_logic := '1' -- fifo almost empty
	);
end fifo_dc;

architecture magic of fifo_dc is
    type fifo_line is array(DEPTH-1 downto 0) of std_logic_vector(D_WIDTH-1 downto 0);
    signal fl : fifo_line := (others => (others => '0'));
	signal head, tail : unsigned(integer(ceil(log2(real(DEPTH+1)))) downto 0) := (others => '0');
	signal fill : unsigned(integer(ceil(log2(real(DEPTH+1)))) downto 0) := (others => '0');
	signal fifo_full : std_logic := '0';
	signal fifo_empty : std_logic := '1';
begin
	process(clk_a_i)
	begin
		if rising_edge(clk_a_i) and en_i='1' then
            fl <= fl(DEPTH-2 downto 0) & data_i;
            if fifo_full='0' then
                if head<DEPTH then
                    head <= head + 1;
                else
                    head <= (others => '0');
                end if;
			end if;
		end if;
	end process;

	process(clk_b_i)
	begin
		if rising_edge(clk_b_i) then
            data_o <= fl(to_integer(head)-to_integer(tail)-1) when head>tail else
                fl(DEPTH-1-(to_integer(tail)-to_integer(head)-1)) when tail>head;
            if fifo_empty='0' then
                if tail<DEPTH then
                    tail <= tail + 1;
                else
                    tail <= (others => '0');
                end if;
			end if;
		end if;
	end process;

	fifo_full <= '1' when head=tail-1 or (head=DEPTH and tail=0) else '0';
	fifo_empty <= '1' when tail=head else '0';
	fill <= head-tail when head>=tail else
        DEPTH-(tail-head-1) when tail>head;
	fifo_ae <= '0' when fill>DEPTH/2-1 else '1';
end magic;
