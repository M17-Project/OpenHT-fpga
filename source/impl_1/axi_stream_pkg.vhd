-------------------------------------------------------------
-- AXI stream package
--
-- Sebastien Van Cauwenberghe, ON4SEB
-- 
-- Reference : https://developer.arm.com/documentation/ihi0051/latest/
-- AXI stream spec IHI 0051B
-- M17 Project
-- July 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package axi_stream_pkg is
    constant AXIS_IQ_TDATA_SIZE : natural := 32;
    constant AXIS_MOD_TDATA_SIZE : natural := 16;

    type axis_in_iq_t is record
        tdata : std_logic_vector(AXIS_IQ_TDATA_SIZE-1 downto 0); -- DATA I(31->16), Q(15->0)
        tvalid : std_logic; -- Data is valid
        tlast : std_logic; -- Last burst of packet
    end record;
    constant axis_in_iq_null : axis_in_iq_t := ((others => '0'), '0', '0');

    type axis_out_iq_t is record
        tready : std_logic; -- Downstream is ready
    end record;

    type axis_in_mod_t is record
        tdata : std_logic_vector(AXIS_MOD_TDATA_SIZE-1 downto 0);
        tvalid : std_logic; -- Data is valid
        tlast : std_logic; -- Last burst of packet
    end record;
    constant axis_in_mod_null : axis_in_mod_t := ((others => '0'), '0', '0');

    type axis_out_mod_t is record
        tready : std_logic; -- Downstream is ready
    end record;
end package;
