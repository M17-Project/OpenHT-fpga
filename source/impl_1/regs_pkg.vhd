-------------------------------------------------------------
-- Registers package
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package regs_pkg is
	constant RW_REGS_NUM	: integer := 13;
	constant R_REGS_NUM		: integer := 8;

	type t_rw_regs is array(0 to RW_REGS_NUM-1) of std_logic_vector(15 downto 0);
	type t_r_regs is array(0 to R_REGS_NUM-1) of std_logic_vector(15 downto 0);
end regs_pkg;

package body regs_pkg is
	--
end regs_pkg;