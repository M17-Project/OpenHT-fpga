GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) spi_tx_test.vhd spi_tx.vhd
	@$(GHDL) -e $(FLAGS) spi_tx_test
	@$(GHDL) -r $(FLAGS) spi_tx_test --wave=spi_tx_test.ghw --stop-time=10ms
