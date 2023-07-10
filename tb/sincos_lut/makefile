GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) sincos_lut_test.vhd sincos_lut.vhd
	@$(GHDL) -e $(FLAGS) sincos_lut_test
	@$(GHDL) -r $(FLAGS) sincos_lut_test --wave=sincos_lut_test.ghw --stop-time=110ms
