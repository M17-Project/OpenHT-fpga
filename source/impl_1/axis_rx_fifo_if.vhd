library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axi_stream_pkg.all;

entity axis_rx_fifo_if is
    generic (
        G_DATA_SIZE : natural
    );
    port (
        clk   : in std_logic;
        nrst  : in std_logic;

        s_axis_i : in axis_in_iq_t;
        s_axis_o : out axis_out_iq_t;
        
        fifo_wr_en : out std_logic;
		fifo_wr_data : out std_logic_vector(G_DATA_SIZE-1 downto 0);
		fifo_full : in std_logic
    );
end entity axis_rx_fifo_if;

architecture rtl of axis_rx_fifo_if is

begin
    fifo_wr_en <= s_axis_i.tvalid and not fifo_full;
    fifo_wr_data <= s_axis_i.tdata(31 downto 16); -- Real part only
    -- TODO do something with TSTRB
    
end architecture;