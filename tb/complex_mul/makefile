GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) complex_mul_test.vhd complex_mul.vhd
	@$(GHDL) -e $(FLAGS) complex_mul_test
	@$(GHDL) -r $(FLAGS) complex_mul_test --wave=complex_mul_test.ghw --stop-time=10ms
