-------------------------------------------------------------
-- APB decoder
--
-- Sebastien Van Cauwenberghe, ON4SEB
--
-- Reference: https://developer.arm.com/documentation/ihi0024/latest/
-- APB spec IHI0024E
-- M17 Project
-- September 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.apb_pkg.all;

entity apb_merge is
    generic (
        N_SLAVES : integer
    );
    port (
        clk_i   : in std_logic;
        rstn_i  : in std_logic;

        m_apb_in : in apb_in_t;
        m_apb_out : out apb_out_t;

        s_apb_in : out apb_in_t;
        s_apb_out : in apb_out_arr_t(0 to N_SLAVES-1)
    );
end entity apb_merge;

architecture rtl of apb_merge is

begin
    s_apb_in <= m_apb_in;
    
    process (all)
        variable v_apb_out : apb_out_t;
    begin
        v_apb_out := apb_out_null;
        for i in 0 to N_SLAVES-1 loop
            v_apb_out.PRDATA := v_apb_out.PRDATA or s_apb_out(i).PRDATA;
            v_apb_out.PREADY := v_apb_out.PREADY or s_apb_out(i).PREADY;
        end loop;
        m_apb_out <= v_apb_out;
    end process;
end architecture;
