create_clock -name {clk_i} -period 38.4615384615385 [get_ports clk_i]
create_clock -name {clk_rx_i} -period 15.625 [get_ports clk_rx_i]
create_generated_clock -name {clk_64} -source [get_ports clk_i] -divide_by 19000 -multiply_by 46769 [get_nets clk_64]
