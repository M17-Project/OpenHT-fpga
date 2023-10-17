create_clock -name {clk_i} -period 31.25 [get_ports clk_i]
create_clock -name {clk_rx_i} -period 15.625 [get_ports clk_rx_i]
create_clock -name {clk_tx_ddr} -period 15.625
set_output_delay -clock [get_clocks clk_tx_ddr] -max 0 [get_ports clk_tx_o]
set_output_delay -clock [get_clocks clk_tx_ddr] -min 0 [get_ports clk_tx_o]
set_output_delay -clock [get_clocks clk_tx_ddr] -min 1.5 [get_ports data_tx_o]
set_output_delay -clock [get_clocks clk_tx_ddr] -max 5.5 [get_ports data_tx_o]

set_false_path -to [get_ports spi_miso]
set_false_path -from [get_ports {spi_mosi spi_ncs spi_sck}]
