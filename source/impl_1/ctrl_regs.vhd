--control registers
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ctrl_regs is
	port(
		clk_i		: in std_logic;							-- clock in
		rst			: in std_logic;							-- reset
		d_i			: in std_logic_vector(31 downto 0);		-- data in
		ib_o		: out std_logic_vector(15 downto 0);	-- I balance out
		qb_o		: out std_logic_vector(15 downto 0);	-- Q balance out
		ai_o		: out std_logic_vector(15 downto 0);	-- I offset out
		aq_o		: out std_logic_vector(15 downto 0);	-- Q offset out
		mod_o		: out std_logic_vector(15 downto 0);	-- modulation register
		ctrl_o		: out std_logic_vector(15 downto 0)		-- control register
	);
end ctrl_regs;

architecture magic of ctrl_regs is
	signal addr : std_logic_vector(15 downto 0) := (others => '0');
	signal v  : std_logic_vector(15 downto 0) := (others => '0');
	
	type config_regs is array(integer range 0 to 6) of std_logic_vector(15 downto 0);
	constant init : config_regs := (x"0000", x"3C80", x"4000", x"0200", x"FF40", x"3127", x"0002");
	signal config : config_regs := (others => (others => '0'));
begin
	addr <= d_i(31 downto 16);
	v <= d_i(15 downto 0);
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst='0' then
				if addr=x"0001" then
					config(1) <= v;
				end if;
				if addr=x"0002" then
					config(2) <= v;
				end if;
				if addr=x"0003" then
					config(3) <= v;
				end if;
				if addr=x"0004" then
					config(4) <= v;
				end if;
				if addr=x"0005" then
					config(5) <= v;
				end if;
				if addr=x"0006" then
					config(6) <= v;
				end if;
			else
				for i in 1 to 6 loop
					config(i) <= init(i);
				end loop;
			end if;
		end if;
	end process;
	
	ib_o	<= config(1);
	qb_o	<= config(2);
	ai_o	<= config(3);
	aq_o	<= config(4);
	mod_o	<= config(5);
	ctrl_o	<= config(6);
end magic;