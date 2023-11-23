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
    constant APB_ADDR_SIZE: positive := 16;
    constant APB_DATA_SIZE: positive := 16;
    constant APB_SLAVE_CNT: positive := 13;
    constant APB_PSELID_BITS : positive := 4;

    constant PSEL_TX_CTRL : natural := 0;

    type apb_state_t is (APB_IDLE, APB_SETUP, APB_ACCESS);

    type apb_in_t is record
        PADDR : std_logic_vector(APB_ADDR_SIZE-1 downto 0);
        PSEL : std_logic_vector(APB_SLAVE_CNT-1 downto 0);
        PWRITE : std_logic;
        PENABLE : std_logic;
        PWDATA : std_logic_vector(APB_DATA_SIZE-1 downto 0);
    end record;
    constant apb_in_null : apb_in_t := ((others => '0'), (others => '0'), '0', '0', (others => '0'));

    type apb_out_t is record
        PRDATA : std_logic_vector(APB_DATA_SIZE-1 downto 0);
        PREADY : std_logic;
    end record;
    constant apb_out_null : apb_out_t := (PRDATA => (others => '0'), PREADY => '0');

    type apb_out_arr_t is array (natural range <>) of apb_out_t;

    constant C_COM_REGS_PSEL : integer := 0;
    constant C_TX_REGS_PSEL : integer := 1;
    constant C_TX_PREFILTER_PSEL : integer := 2;
    constant C_TX_CTCSS_PSEL : integer := 3;
    constant C_TX_INTERP0_PSEL : integer := 4;
    constant C_TX_INTERP1_PSEL : integer := 5;
    constant C_TX_INTERP2_PSEL : integer := 6;
    constant C_TX_IQ_GAIN_PSEL : integer := 7;
    constant C_TX_IQ_OFFSET_PSEL : integer := 8;
    constant C_RX_DEC0_PSEL : integer := 9;
    constant C_RX_DEC1_PSEL : integer := 10;
    constant C_RX_DEC2_PSEL : integer := 11;
    constant C_RX_POSTFILTER_PSEL : integer := 12;

end package;