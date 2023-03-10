library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package regs_pkg is
	type t_rw_regs is array(0 to 15) of std_logic_vector(15 downto 0);
	type t_r_regs is array(0 to 3) of std_logic_vector(15 downto 0);
end regs_pkg;

package body regs_pkg is
	--
end regs_pkg;