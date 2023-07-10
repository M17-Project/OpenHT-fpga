GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) spi_slave_test.vhd spi_slave.vhd
	@$(GHDL) -e $(FLAGS) spi_slave_test
	@$(GHDL) -r $(FLAGS) spi_slave_test --wave=spi_slave_test.ghw --stop-time=11500us
