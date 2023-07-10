GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) spi_rx_test.vhd spi_rx.vhd
	@$(GHDL) -e $(FLAGS) spi_receiver_test
	@$(GHDL) -r $(FLAGS) spi_receiver_test --wave=spi_test.ghw --stop-time=20ms
