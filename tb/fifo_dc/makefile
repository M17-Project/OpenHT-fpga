GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) fifo_dc_test.vhd fifo_dc.vhd
	@$(GHDL) -e $(FLAGS) fifo_dc_test
	@$(GHDL) -r $(FLAGS) fifo_dc_test --wave=fifo_dc_test.ghw --stop-time=100ms
