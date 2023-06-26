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
	signal cnt : unsigned(integer(ceil(log2(real(DEPTH)))) downto 0) := (others => '0');
begin
	process(clk_a_i, clk_b_i)
	begin
		if en_i = '1' then
			if rising_edge(clk_a_i) then
				if cnt<DEPTH then
					fl <= fl(DEPTH-2 downto 0) & data_i;
					if cnt=0 then data_o <= data_i; end if;
					cnt <= cnt + 1;
				end if;
			end if;

			if rising_edge(clk_b_i) then
				if cnt>0 then
					data_o <= fl(to_integer(cnt)-1);
					cnt <= cnt - 1;
				end if;
			end if;
		end if;
	end process;

	fifo_ae <= '0' when cnt>DEPTH/2-1 else '1';
end magic;
