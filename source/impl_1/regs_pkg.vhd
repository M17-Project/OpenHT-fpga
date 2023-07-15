-------------------------------------------------------------
-- Registers package
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package regs_pkg is
	-- regs topology
	constant RW_REGS_NUM	: integer := 16;
	constant R_REGS_NUM		: integer := 8;
	
	-- offsets RW regs
	constant CR_1			: integer := 0;
	constant CR_2			: integer := 1;
	constant CR_3			: integer := 2;
	constant CR_4			: integer := 3;
	
	constant I_OFFS			: integer := 4;
	constant Q_OFFS			: integer := 5;
	constant I_GAIN			: integer := 6;
	constant Q_GAIN			: integer := 7;
	constant DPD_1			: integer := 8;
	constant DPD_2			: integer := 9;
	constant DPD_3			: integer := 10;
	
	constant MOD_IN			: integer := 11;
	
	constant FM_1			: integer := 12;
	constant FM_2			: integer := 13;
	constant SSB_1			: integer := 14;
	constant SSB_2			: integer := 15;
	
	-- offsets R regs
	constant SR_1			: integer := 0;
	constant SR_2			: integer := 1;
	constant SR_3			: integer := 2;
	constant SR_4			: integer := 3;
	constant SR_5			: integer := 4;
	constant SR_6			: integer := 5;
	constant SR_7			: integer := 6;
	constant DEMOD_OUT		: integer := 7;
	
	-- type definitions
	type t_rw_regs is array(0 to RW_REGS_NUM-1) of std_logic_vector(15 downto 0);
	type t_r_regs is array(0 to R_REGS_NUM-1) of std_logic_vector(15 downto 0);
end regs_pkg;

package body regs_pkg is
	--
end regs_pkg;
