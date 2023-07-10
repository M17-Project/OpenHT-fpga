--ctrl_regs test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package regs_pkg is
	type t_rw_regs is array(0 to 15) of std_logic_vector(15 downto 0);
	type t_r_regs is array(0 to 3) of std_logic_vector(15 downto 0);
end package;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.regs_pkg.all;

entity ctrl_regs_test is
	--
end ctrl_regs_test;

architecture sim of ctrl_regs_test is
	component ctrl_regs is
		port(
			clk_i		: in std_logic;							-- clock in
			nrst		: in std_logic;							-- reset
			addr_i		: in std_logic_vector(15 downto 0);		-- address in
			data_i		: in std_logic_vector(15 downto 0);		-- data in
			data_o		: out std_logic_vector(15 downto 0);	-- data out
			rw_i		: in std_logic;							-- read/write flag, r:0 w:1
			latch_i		: in std_logic;							-- latch signal (rising edge)
			regs_rw		: inout t_rw_regs;
			regs_r		: in t_r_regs
		);
	end component;

	signal clk_i, rw : std_logic := '0';
	signal latch, nrst : std_logic := '1';
	signal data_i, data_o, addr_i : std_logic_vector(15 downto 0) := (others => '0');
	signal regs_rw : t_rw_regs := (others => (others => '0'));
	signal regs_r : t_r_regs := (others => (others => '0'));
begin
	dut: ctrl_regs port map(
		clk_i => clk_i,
		nrst => nrst,
		addr_i => addr_i,
		data_i => data_i,
		data_o => data_o,
		rw_i => rw,
		latch_i	=> latch,
		regs_rw => regs_rw,
		regs_r => regs_r
	);

	process
	begin
		rw <= '0';
		addr_i <= x"0000";

		wait for 0.5 ms;
		latch <= '0';
		wait for 0.1 ms;
		addr_i <= x"0010";
		rw <= '0';
		wait for 0.1 ms;
		data_i <= x"0000";
		latch <= '1';
		rw <= '0';

		wait for 0.5 ms;
		latch <= '0';
		wait for 0.1 ms;
		addr_i <= x"0001";
		rw <= '1';
		wait for 0.1 ms;
		data_i <= x"BEEF";
		latch <= '1';
		rw <= '0';
		
		wait;
	end process;

	process
	begin
		wait for 0.1 ms;
		nrst <= '0';
		wait for 0.1 ms;
		nrst <= '1';
		wait;
	end process;

	process
	begin
		clk_i <= not clk_i;
		wait for 0.01 ms;
		regs_r(0)(0) <= '1';
	end process;
end sim;
