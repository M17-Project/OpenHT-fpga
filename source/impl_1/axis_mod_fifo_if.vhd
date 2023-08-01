library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;

entity axis_mod_fifo_if is
    generic (
        G_DATA_SIZE : natural
    );
    port (
        clk   : in std_logic;
        nrst  : in std_logic;
        fifo_rd_en : out std_logic;
		fifo_rd_data : in std_logic_vector(G_DATA_SIZE-1 downto 0);
		fifo_ae : in std_logic;
		fifo_empty : in std_logic;

        m_axis_mod_o : out axis_in_mod_t;
        m_axis_mod_i : in axis_out_mod_t
    );
end entity axis_mod_fifo_if;

architecture rtl of axis_mod_fifo_if is

begin
    fifo_rd_en <= m_axis_mod_i.tready and not fifo_empty;
    
    m_axis_mod_o.tdata <= fifo_rd_data;
    m_axis_mod_o.tvalid <= not fifo_empty;

end architecture;