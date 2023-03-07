--magnitude estimator
--mag=sqrt(i^2+q^2)
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mag_est is
	port(
		clk_i		: in std_logic;
		trig_i		: in std_logic;
		i_i, q_i	: in signed(15 downto 0);
		est_o		: out unsigned(15 downto 0) := (others => '0');
		rdy_o		: out std_logic := '0'
	);
end mag_est;

architecture magic of mag_est is
	signal busy : std_logic := '0';
	signal sum_sq : unsigned(31 downto 0) := (others => '0');
	signal p_trig, pp_trig : std_logic := '0';
	signal sq_est : unsigned(15 downto 0) := (others => '0');
	signal cnt : unsigned(5 downto 0) := (others => '0');
begin
	process(clk_i)
		variable bit_cnt : integer range 0 to 16 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			if pp_trig='0' and p_trig='1' then
				if busy='0' then
					busy <= '1';
					sum_sq <= unsigned(i_i*i_i) + unsigned(q_i*q_i);
					sq_est <= (others => '0');
				end if;
			end if;

			if busy='1' then
				if cnt=32 then
					est_o <= sq_est;
					cnt <= (others => '0');
					bit_cnt := 0;
					busy <= '0';
				else
					if cnt(0)='0' then
						sq_est(15-bit_cnt) <= '1';
					else
						if sq_est*sq_est>sum_sq then
							sq_est(15-bit_cnt) <= '0';
						end if;
						bit_cnt := bit_cnt + 1;
					end if;

					cnt <= cnt + 1;
				end if;
			end if;
		end if;
	end process;
	
	rdy_o <= not busy;
end magic;
