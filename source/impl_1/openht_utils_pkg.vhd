library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package openht_utils_pkg is
    function log2up (val : natural) return natural;

    type taps_mod_t is array (natural range<>) of signed;

end package;

package body openht_utils_pkg is

    function log2up (val : natural) return natural is
        variable log_val : natural;
    begin
        log_val := 0;
        while val >= 2**log_val loop
            log_val := log_val + 1;
        end loop;
        return log_val;
    end function;

end package body;