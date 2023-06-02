-------------------------------------------------------------
-- Control registers
--
-- The register map is as follows:
--
--  15             0
-- |----------------|
-- |                | START = 0x0000
-- |  RW_REGS_NUM   |
-- |    R/W regs    | 
-- |                | END = RW_REGS_NUM-1
-- |----------------|
-- |                | START = RW_REGS_NUM
-- |   R_REGS_NUM   | 
-- |     R regs     | 
-- |                | END = RW_REGS_NUM+R_REGS_NUM-1
-- |----------------|
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.regs_pkg.all;

entity ctrl_regs is
	port(
		clk_i		: in std_logic;											-- clock in
		nrst		: in std_logic;											-- reset
		addr_i		: in std_logic_vector(14 downto 0);						-- address in
		data_i		: in std_logic_vector(15 downto 0);						-- data in
		data_o		: out std_logic_vector(15 downto 0) := (others => '0');	-- data out
		rw_i		: in std_logic;											-- read/write flag, r:0 w:1
		latch_i		: in std_logic;											-- latch signal (rising edge)
		-- registers
		regs_rw		: inout t_rw_regs := (others => (others => '0'));
		regs_r		: in t_r_regs
	);
end ctrl_regs;

architecture magic of ctrl_regs is
	type rw_regs is array(0 to RW_REGS_NUM-1) of std_logic_vector(15 downto 0);
	-- default values for the RW registers
	constant init_rw : rw_regs := (
		x"0000", x"0000", x"0000", x"0000", -- 0x0000 .. 0x0003
		x"4000", x"4000", x"4000", x"0000", -- 0x0004 .. 0x0007
		x"0000", x"0000", x"0000", x"0000", -- 0x0008 .. 0x000B
		x"0000"-- x"0000", x"0000", x"0000"  -- 0x000C .. 0x000F
	);

	signal write_pend : std_logic := '0';
	signal p_latch, pp_latch : std_logic := '0';
begin	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			p_latch <= latch_i;
			pp_latch <= p_latch;
			
			if nrst='1' then
				-- check if READ or WRITE
				if rw_i='0' then -- if READ
					-- check where to read from
					if unsigned(addr_i)<RW_REGS_NUM then
						data_o <= regs_rw(to_integer(unsigned(addr_i)));
					else
						data_o <= regs_r(to_integer(unsigned(addr_i)-RW_REGS_NUM));
					end if;
				else -- if WRITE, set the flag and wait for rising edge of the nCS
					write_pend <= '1';
				end if;

				-- latch input rising edge and write pending flag set
				if pp_latch='0' and p_latch='1' and write_pend='1' then
					-- only WRITE if the address points to a writable register
					if unsigned(addr_i)<RW_REGS_NUM then
						regs_rw(to_integer(unsigned(addr_i))) <= data_i;
					end if;
					write_pend <= '0'; -- clear the write pending flag
				end if;
			else -- reset all RW registers to their default values
				for i in 0 to RW_REGS_NUM-1 loop
					regs_rw(i) <= init_rw(i);
				end loop;
			end if;
		end if;
	end process;
end magic;