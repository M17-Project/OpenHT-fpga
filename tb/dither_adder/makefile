GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) dither_adder_test.vhd dither_adder.vhd
	@$(GHDL) -e $(FLAGS) dither_adder_test
	@$(GHDL) -r $(FLAGS) dither_adder_test --wave=dither_adder_test.ghw --stop-time=100ms
