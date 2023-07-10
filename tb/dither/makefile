GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) dither_test.vhd dither.vhd
	@$(GHDL) -e $(FLAGS) dither_test
	@$(GHDL) -r $(FLAGS) dither_test --wave=dither_test.ghw --stop-time=100ms
