GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) serial_fir_test.vhd serial_fir.vhd
	@$(GHDL) -e $(FLAGS) serial_fir_test
	@$(GHDL) -r $(FLAGS) serial_fir_test --wave=serial_fir_test.ghw --stop-time=15ms
