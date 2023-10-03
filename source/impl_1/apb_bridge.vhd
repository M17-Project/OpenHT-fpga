-------------------------------------------------------------
-- APB bridge
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

entity apb_bridge is
    port (
        clk_i   : in std_logic;
        rstn_i  : in std_logic;

		dout	 : in std_logic_vector(15 downto 0) := (others => '0');  -- received data register
		dout_vld : in std_logic;                                         -- Output data valid
		cs       : in std_logic;                                         -- Chip Select
		din	     : out std_logic_vector(15 downto 0);				     -- input data register
		din_vld  : out std_logic;              				             -- input data register valid

        m_apb_in : out apb_in_t;
        m_apb_out : in apb_out_t
    );
end entity apb_bridge;

architecture rtl of apb_bridge is
    type apb_state_ext_t is (APB_IDLE, GOT_ADDRESS, WAIT_FOR_NEW_WORD, APB_SETUP, APB_ACCESS);
    signal apb_state : apb_state_ext_t := APB_IDLE;

    signal address : unsigned(15 downto 0);
    signal autoincrement : std_logic;
    signal rw : std_logic;

    signal data_in : std_logic_vector(15 downto 0);
    signal data_rdy : std_logic;

begin
    data_in <= m_apb_out.prdata;
    data_rdy <= m_apb_out.pready;

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            din_vld <= '0';
            m_apb_in.PSEL <= (others => '0');

            case apb_state is
                when GOT_ADDRESS =>
                    if rw then -- Write
                        if dout_vld then
                            apb_state <= APB_SETUP;
                        end if;
                    else -- Go directly
                        apb_state <= APB_SETUP;
                    end if;

                    -- Go back to capturing address when CS is deasserted
                    if not cs then
                        apb_state <= APB_IDLE;
                    end if;

                when WAIT_FOR_NEW_WORD =>
                    if dout_vld then
                        apb_state <= APB_SETUP;
                    end if;

                    -- Go back to capturing address when CS is deasserted
                    if not cs then
                        apb_state <= APB_IDLE;
                    end if;

                when APB_SETUP =>
                    m_apb_in.PADDR <= std_logic_vector(address);
                    m_apb_in.PWDATA <= dout;
                    m_apb_in.PWRITE <= rw;
                    m_apb_in.PENABLE <= '0';
                    m_apb_in.PSEL <= (others => '0');
                    if to_integer(address(14 downto 14-APB_PSELID_BITS+1)) < APB_SLAVE_CNT then
                        m_apb_in.PSEL(to_integer(address(14 downto 14-APB_PSELID_BITS+1))) <= '1';
                    end if;
                    apb_state <= APB_ACCESS;

                when APB_ACCESS =>
                    m_apb_in.PENABLE <= '1';
                    m_apb_in.PSEL <= (others => '0');
                    if to_integer(address(14 downto 14-APB_PSELID_BITS+1)) < APB_SLAVE_CNT then
                        m_apb_in.PSEL(to_integer(address(14 downto 14-APB_PSELID_BITS+1))) <= '1';
                    end if;

                    if data_rdy then
                        apb_state <= WAIT_FOR_NEW_WORD;
                        din <= data_in;
                        din_vld <= '1';

                        if autoincrement then
                            address <= address + 1;
                        end if;
                    end if;

                when others =>
                    if dout_vld and cs then
                        rw <= dout(15);
                        autoincrement <= dout(14);
                        -- Byte address
                        address <= "0" & unsigned(dout(13 downto 0)) & "0";
                        apb_state <= GOT_ADDRESS;
                    end if;

            end case;
        end if;
    end process;

end architecture;
