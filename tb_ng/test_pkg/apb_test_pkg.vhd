-----------------------------------------
-- APB test helper package
--
-- Based on APB spec IHI0024
-- https://developer.arm.com/documentation/ihi0024/latest/
-- Sebastien, ON4SEB
-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.data_types_context;

use work.apb_pkg.all;

package apb_test_pkg is

    procedure apb_read (
        signal clk : in std_logic;
        constant pselid : in natural;
        signal apb_in : out apb_in_t;
        signal apb_out : in apb_out_t;
        constant address : in std_logic_vector(APB_ADDR_SIZE-1 downto 0);
        variable data : out std_logic_vector(APB_DATA_SIZE-1 downto 0)
    );

    procedure apb_write (
        signal clk : in std_logic;
        constant pselid : in natural;
        signal apb_in : out apb_in_t;
        signal apb_out : in apb_out_t;
        constant address : in std_logic_vector(APB_ADDR_SIZE-1 downto 0);
        constant data : in std_logic_vector(APB_DATA_SIZE-1 downto 0)
    );

end package apb_test_pkg;

package body apb_test_pkg is

    procedure apb_read (
        signal clk : in std_logic;
        constant pselid : in natural;
        signal apb_in : out apb_in_t;
        signal apb_out : in apb_out_t;
        constant address : in std_logic_vector(APB_ADDR_SIZE-1 downto 0);
        variable data : out std_logic_vector(APB_DATA_SIZE-1 downto 0)
    ) is
        variable got_data : boolean;
    begin
        apb_in.PADDR <= address;
        apb_in.psel <= (others => '0');
        apb_in.psel(pselid) <= '1';
        apb_in.penable <= '0';
        apb_in.pwrite <= '0';
        data := (others => 'X');
        got_data := false;
        for i in 0 to 49 loop
            wait until rising_edge(clk);
            if apb_out.pready then
                got_data := true;
                data := apb_out.prdata;
                exit;
            end if;
        end loop;
        check(got_data, "Data not captured within 50 cycles");
    end procedure;

    procedure apb_write (
        signal clk : in std_logic;
        constant pselid : in natural;
        signal apb_in : out apb_in_t;
        signal apb_out : in apb_out_t;
        constant address : in std_logic_vector(APB_ADDR_SIZE-1 downto 0);
        constant data : in std_logic_vector(APB_DATA_SIZE-1 downto 0)
    ) is
        variable did_write : boolean;
    begin
        apb_in.PADDR <= address;
        apb_in.psel <= (others => '0');
        apb_in.psel(pselid) <= '1';
        apb_in.penable <= '0';
        apb_in.pwrite <= '0';
        apb_in.pwdata <= data;
        did_write := false;
        for i in 0 to 49 loop
            wait until rising_edge(clk);
            if apb_out.pready then
                did_write := true;
                exit;
            end if;
        end loop;
        check(did_write, "Data not written within 50 cycles");
    end procedure;

end package body;
