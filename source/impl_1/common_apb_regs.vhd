-------------------------------------------------------------
-- APB common regs
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

entity common_apb_regs is
    generic (
        PSEL_ID : natural;
        REV_MAJOR : natural;
        REV_MINOR : natural
    );
    port (
        clk   : in std_logic;
        s_apb_in : in apb_in_t;
        s_apb_out : out apb_out_t;

        pll_lock : in std_logic;
        io3_sel : out std_logic_vector(2 downto 0);
        io4_sel : out std_logic_vector(2 downto 0);
        io5_sel : out std_logic_vector(2 downto 0);
        io6_sel : out std_logic_vector(2 downto 0);

        tx_data : out std_logic_vector(15 downto 0);
        tx_data_valid : out std_logic;
        rxtx : out std_logic_vector(1 downto 0)
    );
end entity common_apb_regs;

architecture rtl of common_apb_regs is
    signal rxtx_i : std_logic_vector(1 downto 0) := (others => '0');
    signal io3_sel_i : std_logic_vector(2 downto 0) := (others => '0');
    signal io4_sel_i : std_logic_vector(2 downto 0) := (others => '0');
    signal io5_sel_i : std_logic_vector(2 downto 0) := (others => '0');
    signal io6_sel_i : std_logic_vector(2 downto 0) := (others => '0');

begin

    rxtx <= rxtx_i;
    io3_sel <= io3_sel_i;
    io4_sel <= io4_sel_i;
    io5_sel <= io5_sel_i;
    io6_sel <= io6_sel_i;

    process (clk)
    begin
        if rising_edge(clk) then
            s_apb_out.pready <= '0';
            s_apb_out.prdata <= (others => '0');
            tx_data_valid <= '0';

            if s_apb_in.PSEL(PSEL_ID) then
                if s_apb_in.PENABLE and s_apb_in.PWRITE then
                    case s_apb_in.paddr(3 downto 1) is
                        when "000" => -- Version REG
                            null;

                        when "001" => -- Status REG
                            null;

                        when "010" => -- Control REG
                            rxtx_i <= s_apb_in.pwdata(1 downto 0);

                        when "011" => -- IO out reg
                            io3_sel_i <= s_apb_in.pwdata(2 downto 0);
                            io4_sel_i <= s_apb_in.pwdata(5 downto 3);
                            io5_sel_i <= s_apb_in.pwdata(8 downto 6);
                            io6_sel_i <= s_apb_in.pwdata(11 downto 9);

                        when "100" => -- TX Fifo
                            tx_data_valid <= '1';
                            tx_data <= s_apb_in.pwdata;

                        when "101" => -- TX Fifo status
                            null;

                        when others =>
                            null;
                    end case;
                end if;

                if not s_apb_in.PENABLE then
                    case s_apb_in.paddr(3 downto 1) is
                        when "000" => -- VERSION REG
                            s_apb_out.prdata(15 downto 8) <= std_logic_vector(to_unsigned(REV_MAJOR, 8));
                            s_apb_out.prdata(7 downto 0) <= std_logic_vector(to_unsigned(REV_MINOR, 8));

                        when "001" => -- Status REG
                            s_apb_out.prdata(0) <= pll_lock;

                        when "010" => -- Control REG
                            s_apb_out.prdata(1 downto 0) <= rxtx_i;

                        when "011" => -- IO out reg
                            s_apb_out.prdata(2 downto 0) <= io3_sel_i;
                            s_apb_out.prdata(5 downto 3) <= io4_sel_i;
                            s_apb_out.prdata(8 downto 6) <= io5_sel_i;
                            s_apb_out.prdata(11 downto 9) <= io6_sel_i;

                        when "100" => -- TX Fifo
                            null;

                        when "101" => -- TX FIFO status
                            null;

                        when others =>
                            null;
                    end case;
                    s_apb_out.pready <= '1';

                end if;

            end if;

        end if;
    end process;

end architecture;