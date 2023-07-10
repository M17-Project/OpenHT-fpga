GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) sin_lut_test.vhd sin_lut.vhd
	@$(GHDL) -e $(FLAGS) sin_lut_test
	@$(GHDL) -r $(FLAGS) sin_lut_test --wave=sin_lut_test.ghw --stop-time=100ms
