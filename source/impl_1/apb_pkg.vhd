-------------------------------------------------------------
-- APB infrastructure
--
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- Reference: https://developer.arm.com/documentation/ihi0024/latest/
-- APB spec IHI0024E
-- M17 Project
-- August 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package apb_pkg is
    constant APB_ADDR_SIZE: positive := 32;
    constant APB_DATA_SIZE: positive := 32;

    type apb_in_t is record
        PADDR : std_logic_vector(APB_ADDR_SIZE-1 downto 0);
        PSEL : std_logic;
        PENABLE : std_logic;
        PWDATA : std_logic_vector(APB_DATA_SIZE-1 downto 0);
    end record;
    constant apb_in_null : apb_in_t := ((others => '0'), '0', '0', (others => '0'));

    type apb_out_t is record
        PRDATA : std_logic_vector(APB_DATA_SIZE-1 downto 0);
    end record;
    constant apb_out_null : apb_out_t := (PRDATA => (others => '0'));

end package;