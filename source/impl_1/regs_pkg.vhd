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
	-- regs topology
	constant RW_REGS_NUM	: integer := 13;
	constant R_REGS_NUM		: integer := 8;
	
	-- offsets RW regs
	constant CR_1			: integer := 0;
	constant CR_2			: integer := 1;
	constant I_OFFS_NULL	: integer := 2;
	constant Q_OFFS_NULL	: integer := 3;
	constant I_GAIN			: integer := 4;
	constant Q_GAIN			: integer := 5;
	constant DPD_1			: integer := 6;
	constant DPD_2			: integer := 7;
	constant DPD_3			: integer := 8;
	constant MOD_IN			: integer := 9;
	--constant RES_1			: integer := 10;
	--constant RES_2			: integer := 11;
	--constant RES_3			: integer := 12;
	-- offsets R regs
	constant SR_1			: integer := 0;
	constant SR_2			: integer := 1;
	constant DEMOD_REG		: integer := 2;
	constant RSSI_REG		: integer := 3;
	constant I_RAW_REG		: integer := 4;
	constant Q_RAW_REG		: integer := 5;
	constant I_FLT_REG		: integer := 6;
	constant Q_FLT_REG		: integer := 7;

	-- type definitions
	type t_rw_regs is array(0 to RW_REGS_NUM-1) of std_logic_vector(15 downto 0);
	type t_r_regs is array(0 to R_REGS_NUM-1) of std_logic_vector(15 downto 0);
end regs_pkg;

package body regs_pkg is
	--
end regs_pkg;
